//
//  BrowserRootView.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 17/02/2026.
//


import SwiftUI

// struct BrowserRootView: View {
//    @Environment(\.colorScheme) private var colorScheme
//    @EnvironmentObject private var themeManager: ThemeManager
//    @EnvironmentObject private var sessionManager: SessionManager
//
//    let appConfiguration: AppConfiguration
//    let request: LaunchRequest
//    let proxies: [AuthProxy]
//
//    var body: some View {
//        let _ = AppLogger.debug("BrowserRootView body computed - ColorScheme: \(colorScheme == .dark ? "dark" : "light")")
//
//        let state = BrowserWindowState(
//            proxyType: request.proxyType,
//            isolationMode: request.isolationMode,
//            proxies: proxies,
//            userAgent: request.userAgent,
//            sessionManager: sessionManager
//        )
//
//        return BrowserWindowView(
//            state: state,
//            request: request
//        )
//        .environment(\.appTheme, themeManager.theme(for: colorScheme))
//        .environment(\.appConfiguration, appConfiguration)
//    }
// }

struct BrowserRootView: View {
    @StateObject var state: BrowserWindowState
    let menu: BrowserMenuBuilder

    var body: some View {
        VStack(spacing: 0) {
            BrowserTabsStripView(state: state)
                .frame(maxWidth: .infinity)
                // .background(AppBackgroundStyle.browserJetGradient.makeView())

            BrowserChromeView(
                state: state,
                menu: menu,
                onToolbarAction: handleToolbarAction
            )
//            .padding(.vertical)

            // Row 2: address bar (uses selected tab)
            //            if let tab = state.selectedTab {
            //                BrowserAddressBarView(tab: tab)
            //                    .padding(.horizontal, 12)
            //                    .padding(.vertical, 8)
            //                    .background(stateBackground)
            //            }

            // Glass: web content
            if let tab = state.selectedTab {
                WebViewContainer(
                    tab: tab
                ) { url in
                    state.addTab(url: url)
                }
                .id(tab.id) // important for WKWebView switching
            } else {
                EmptyView()
            }
        }
        .background(AppBackgroundStyle.browserJetGradient.makeView())
    }

    private var stateBackground: some View {
        // keep it consistent with your chrome background
        Color.clear
    }

    private func handleToolbarAction(_ action: BrowserToolbarAction) {
        guard let tab = state.selectedTab else { return }

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
            print("Burn proxy + reload pressed")
            
        case .duplicateToTabsMenu:
            print("Duplicate tabs menu pressed") // the popover will print count already

        case .refreshAllTabs:
            print("Refresh ALL tabs pressed")
            
        case .accountManager:
            print("Account manager pressed")

        case .screenshot:
            print("Screenshot pressed")

//        case .moreMenu:
//            print("More menu pressed")
            
        default:
            print("Toolbar action:", action)
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

        BrowserChromeView(
            state: state,
            menu: .default
        ) { _ in }

        //        if let tab = state.selectedTab {
        //            BrowserAddressBarView(tab: tab)
        //                .padding(.horizontal, 12)
        //                .padding(.vertical, 8)
        //                .background(Color.clear)
        //        }

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
