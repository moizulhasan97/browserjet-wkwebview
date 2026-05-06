//
//  BrowserRootView.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 17/02/2026.
//


import SwiftUI
import WebKit

/// Thin wrapper that holds an `@ObservedObject` reference to the currently
/// selected tab so that `BrowserRootView` re-renders whenever any `@Published`
/// property on the tab changes — including `webViewID` after a burn.
private struct SelectedTabWebView: View {
    @ObservedObject var tab: TabModel
    let onOpenInNewTab: (URL) -> Void
    
    var body: some View {
        WebViewContainer(tab: tab, onOpenInNewTab: onOpenInNewTab)
            .id(tab.webViewID)
    }
}

struct BrowserRootView: View {
    @StateObject var state: BrowserWindowState
    let menu: BrowserMenuBuilder
    @Environment(\.appConfiguration) private var config
    @EnvironmentObject private var sessionManager: SessionManager
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var forceGate = ForceUpdateGate.shared
    @StateObject private var changeKeyViewModel = ChangeLicenseKeyViewModel()
    @State private var showChangeKeySheet: Bool = false
    @State private var showChangeKeySuccessAlert: Bool = false
    private let keyValueStore: KeyValueStoring
    
    init(
        state: BrowserWindowState,
        menu: BrowserMenuBuilder,
        keyValueStore: KeyValueStoring = UserDefaultsKeyValueStore()
    ) {
        _state = StateObject(wrappedValue: state)
        self.menu = menu
        self.keyValueStore = keyValueStore
    }
    
    var body: some View {
        Group {
            if forceGate.isBlocking {
                ForceUpdateBlockingOverlay()
            } else {
                browserMainContent
            }
        }
        .environment(\.appTheme, themeManager.theme(for: colorScheme))
        .environment(\.designSystem, DesignSystem())
    }
    
    private var currentUserEmail: String? {
        let email = (keyValueStore.object(forKey: StorageKeys.userEmail) as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let email, !email.isEmpty else { return nil }
        return email
    }
    
    private func openIfAvailable(_ url: URL?) {
        guard let url else {
            AppLogger.warning("More menu URL unavailable")
            return
        }
        open(url)
    }
    
    private var browserMainContent: some View {
        VStack(spacing: 0) {
            BrowserTabsStripView(state: state)
                .frame(maxWidth: .infinity)
            
            BrowserChromeView(
                state: state,
                menu: menu,
                onToolbarAction: handleToolbarAction,
                onMoreMenuSelect: handleMoreMenuItem,
                onDuplicateTabs: duplicateSelectedTab
            )
            
            if let tab = state.selectedTab {
                SelectedTabWebView(tab: tab) { url in
                    if state.isTrialLockActive {
                        tab.load(url)
                    } else {
                        state.addTab(url: url)
                    }
                }
            } else {
                EmptyView()
            }
        }
        .background(AppBackgroundStyle.browserJetGradient.makeView())
        .task {
            await BrowserLicenseBackgroundMonitor.run()
        }
        .sheet(isPresented: $showChangeKeySheet) {
            ChangeLicenseKeyView(viewModel: changeKeyViewModel)
        }
        .sheet(isPresented: $showChangeKeySuccessAlert) {
            InfoAlertView(
                title: ActivationMessages.ChangeKeySuccess.title,
                message: ActivationMessages.ChangeKeySuccess.message,
                buttonTitle: ActivationMessages.okButtonTitle,
                onDismiss: {
                    showChangeKeySuccessAlert = false
                    AppUtils.relaunchApplication()
                }
            )
        }
        .onChange(of: changeKeyViewModel.didSucceed) { _, didSucceed in
            guard didSucceed else { return }
            showChangeKeySheet = false
            showChangeKeySuccessAlert = true
        }
    }
    
    private func handleToolbarAction(_ action: BrowserToolbarAction) {
        guard let tab = state.selectedTab else { return }
        if state.isTrialLockActive, action != .reload { return }
        
        switch action {
        case .back:
            tab.webView.goBack()
        case .forward:
            tab.webView.goForward()
        case .reload:
            tab.webView.reload()
            
        case .newTab:
            state.addTab()
            
        case .burnProxyAndReload:
            state.burnProxyAndReloadSelectedTab()
            
        case .refreshAllTabs:
            refreshAllTabs()
            
        case .accountManager:
            print("Account manager pressed")
            
        case .screenshot:
            takeScreenshotOfSelectedTab()
            
            //        case .moreMenu:
            //            print("More menu pressed")
            
        default:
            print("Toolbar action:", action)
        }
    }
    
    private func handleMoreMenuItem(_ item: BrowserMoreMenuItem) {
        if state.isTrialLockActive { return }
        switch item {
        case .paymentCard:
            openIfAvailable(URLConstants.updateYourCardURL(email: currentUserEmail))
        case .buyLicenses:
            openIfAvailable(URLConstants.buyMoreLicensesURL(email: currentUserEmail))
        case .contactUs:
            openIfAvailable(URLConstants.contactUsURL)
        case .twitter:
            openIfAvailable(URLConstants.twitterURL)
            
        case .changeKey:
            changeKeyViewModel.reset()
            showChangeKeySheet = true
            
        case .about:
            print("MoreMenu: About Browser Jet")
        }
    }
    
    private func open(_ url: URL) {
        // "can open new tab?" rule:
        // - sessionManager can create
        // - AND max tabs not exceeded
        if sessionManager.canCreateSession && state.tabs.count < config.maxBrowserTabs {
            state.addTab(url: url)
        } else {
            state.selectedTab?.load(url)
        }
    }
    
    private func refreshAllTabs() {
        for tab in state.tabs {
            tab.webView.reload()
        }
        print("Refresh all tabs: \(state.tabs.count)")
    }
    
    private func duplicateSelectedTab(count: Int) {
        guard let selected = state.selectedTab else { return }
        let url = selected.webView.url ?? URL(string: selected.addressText) ?? URL(string: "about:blank")!
        
        // duplicate current tab URL N times
        for _ in 0..<count {
            state.addTab(url: url)
        }
        print("Duplicated tab \(count)x -> \(url.absoluteString)")
    }
    
    private func takeScreenshotOfSelectedTab() {
        guard let tab = state.selectedTab else { return }
        
        let config = WKSnapshotConfiguration()
        tab.webView.takeSnapshot(with: config) { image, error in
            if let error {
                print("Screenshot failed: \(error.localizedDescription)")
                return
            }
            guard let image else {
                print("Screenshot failed: no image")
                return
            }
            
            // Simple MVP: save to Desktop
            guard let tiff = image.tiffRepresentation,
                  let rep = NSBitmapImageRep(data: tiff),
                  let png = rep.representation(using: .png, properties: [:]) else {
                print("Screenshot failed: could not encode PNG")
                return
            }
            
            let fileName = "BrowserJet-\(Int(Date().timeIntervalSince1970)).png"
            let desktop = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
            let url = desktop.appendingPathComponent(fileName)
            
            do {
                try png.write(to: url)
                print("Screenshot saved: \(url.path)")
            } catch {
                print("Screenshot save failed: \(error.localizedDescription)")
            }
        }
    }
}

#Preview("BrowserRootView (Safe Preview)") {
    let theme = BrowserJetLightTheme()
    let sessionManager = SessionManager(maxSessions: 10)
    
    // Minimal state for preview (local, perTab, no proxies, no UA)
    let state = BrowserWindowState(
        proxyType: .local,
        isolationMode: .perTab,
        proxies: [],
        userAgent: nil,
        sessionManager: sessionManager,
        // swiftlint:disable:next force_unwrapping
        initialURL: URL(string: "https://www.google.com")!,
        initialTabCount: 2
    )
    
    state.addTab()
    state.addTab()
    state.addTab()
    state.addTab()
    state.addTab()
    state.addTab()
    
    return VStack(spacing: 0) {
        BrowserTabsStripView(state: state)
            .frame(maxWidth: .infinity)
        
        return BrowserChromeView(
            state: state,
            menu: .default,
            onToolbarAction: {_ in},
            onMoreMenuSelect: {_ in}
        )
        
        // Placeholder "glass"
        Rectangle()
            .overlay {
                Text("WebView (Preview Placeholder)")
                    .font(.system(size: 16, weight: .semibold))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .frame(width: 1200, height: 780)
    .background(AppBackgroundStyle.browserJetGradient.makeView())
    .environment(\.appTheme, theme)
    .environmentObject(sessionManager)
}
