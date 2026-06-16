//
//  BrowserRootView.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 17/02/2026.
//

import SwiftUI
import WebKit

private struct SelectedTabWebView: View {
    @ObservedObject var tab: TabModel
    let onOpenInNewTab: (URL) -> Void

    var body: some View {
        WebViewContainer(tab: tab, onOpenInNewTab: onOpenInNewTab)
            .id(tab.webViewID)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct BrowserRootView: View {
    @StateObject var state: BrowserWindowState
    @StateObject private var changeKeyViewModel = ChangeLicenseKeyViewModel()

    @Environment(\.appConfiguration)
    private var config

    @Environment(\.colorScheme)
    private var colorScheme

    @EnvironmentObject private var sessionManager: SessionManager
    @EnvironmentObject private var themeManager: ThemeManager

    @ObservedObject private var forceGate = ForceUpdateGate.shared

    @State private var showChangeKeySheet: Bool = false
    @State private var showChangeKeySuccessAlert: Bool = false

    private let keyValueStore: KeyValueStoring
    let menu: BrowserMenuBuilder

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
        .browserJetThemedRoot(themeManager: themeManager, colorScheme: colorScheme)
        .onAppear {
            ActiveBrowserStateProvider.shared.current = state
        }
        .onDisappear {
            if ActiveBrowserStateProvider.shared.current === state {
                ActiveBrowserStateProvider.shared.current = nil
            }
        }
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
            BrowserChromeView(
                state: state,
                menu: menu,
                onToolbarAction: handleToolbarAction,
                onMoreMenuSelect: handleMoreMenuItem
            )                { count in state.duplicateSelectedTab(count: count) }
            .frame(maxWidth: .infinity)

            if let tab = state.selectedTab {
                SelectedTabWebView(tab: tab) { url in
                    if state.isTrialLockActive {
                        tab.load(url)
                    } else {
                        state.addTab(url: url)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                EmptyView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                buttonTitle: ActivationMessages.okButtonTitle
            ) {
                showChangeKeySuccessAlert = false
                AppUtils.relaunchApplication()
            }
        }
        .onChange(of: changeKeyViewModel.didSucceed) { _, didSucceed in
            guard didSucceed else { return }
            showChangeKeySheet = false
            Task { @MainActor in
                showChangeKeySuccessAlert = true
            }
        }
    }

    private func handleToolbarAction(_ action: BrowserToolbarAction) {
        guard let tab = state.selectedTab else { return }
        if state.isTrialLockActive, action != .reload, action != .stop { return }

        if handleNavigationAction(action, on: tab) { return }
        handleStateAction(action)
    }

    private func handleNavigationAction(_ action: BrowserToolbarAction, on tab: TabModel) -> Bool {
        switch action {
        case .back:
            tab.webView.goBack()
            return true
        case .forward:
            tab.webView.goForward()
            return true
        case .reload:
            tab.webView.reload()
            return true
        case .stop:
            tab.webView.stopLoading()
            return true
        default:
            return false
        }
    }

    private func handleStateAction(_ action: BrowserToolbarAction) {
        switch action {
        case .newTab:
            state.addTab()
        case .burnProxyAndReload:
            state.burnProxyAndReloadSelectedTab()
        case .refreshAllTabs:
            state.reloadAllTabs()
        case .screenshot:
            state.takeScreenshotOfSelectedTab()
        default:
            AppLogger.info("Toolbar action: \(action)")
        }
    }

    private func handleMoreMenuItem(_ item: BrowserMoreMenuItem) {
        //        if item == .about {
        //            AboutBrowserJetWindowController.shared.show(
        //                themeManager: themeManager,
        //                colorScheme: colorScheme
        //            )
        //            return
        //        }
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
            //        case .about:
            //            break
        }
    }

    private func open(_ url: URL) {
        if sessionManager.canCreateSession && state.tabs.count < state.maxBrowserTabs {
            state.addTab(url: url)
        } else {
            state.selectedTab?.load(url)
        }
    }
}

#Preview("BrowserRootView (Safe Preview)") {
    let theme = BrowserJetLightTheme()
    let sessionManager = SessionManager(maxSessions: 20)

    let state = BrowserWindowState(
        proxyType: .local,
        isolationMode: .perTab,
        proxies: [],
        userAgent: nil,
        sessionManager: sessionManager,
        // swiftlint:disable:next force_unwrapping
        initialURL: URL(string: "https://www.google.com")!,
        initialTabCount: 2,
        maxBrowserTabs: 20
    )

    state.addTab()
    state.addTab()
    state.addTab()

    return VStack(spacing: 0) {
        BrowserTabsStripView(state: state)
            .frame(maxWidth: .infinity)

        BrowserChromeView(
            state: state,
            menu: .default,
            onToolbarAction: { _ in },
            onMoreMenuSelect: { _ in }
        )

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
