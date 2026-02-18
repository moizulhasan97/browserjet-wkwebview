//
//  BrowserChromeView.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 16/02/2026.
//


import SwiftUI

struct BrowserChromeView: View {
    @ObservedObject var state: BrowserWindowState
    let menu: BrowserMenuBuilder
    let onToolbarAction: (BrowserToolbarAction) -> Void

    @Environment(\.appTheme) private var theme

    private var stateBackground: some View {
        // keep it consistent with your chrome background
        Color.clear
    }

    var body: some View {
        HStack(spacing: 10) {
            BrowserToolbarView(
                actions: menu.leading,
                onAction: onToolbarAction
            )

            if let tab = state.selectedTab {
                BrowserAddressBarView(tab: tab)
                    .background(stateBackground)
                    .frame(maxWidth: .infinity)
            }

            BrowserConnectionBadgeView(proxyType: state.proxyType)

            BrowserToolbarView(
                actions: menu.trailing,
                onAction: onToolbarAction
            )
        }
        // .padding(.horizontal, 12)
        .padding(.vertical, 4)
        // .background(theme.surfaceCard.opacity(0.65))
        //        .overlay(
        //            Rectangle()
        //                .frame(height: 1)
        //                .foregroundStyle(theme.divider),
        //            alignment: .bottom
        //        )
    }
}

#Preview("Browser Chrome – Light") {
    let sessionManager = SessionManager()

    let state = BrowserWindowState(
        proxyType: .local,
        isolationMode: .perTab,
        proxies: [],
        userAgent: nil,
        sessionManager: sessionManager,
        initialURL: URL(string: "https://google.com")!,
        initialTabCount: 2
    )

    // Add some sample tabs for preview
    state.tabs = [
        TabModel(
            sessionSlot: 0,
            startURL: URL(string: "https://google.com")!,
            dataStore: .default(),
            proxyType: .local,
            authProxy: nil,
            userAgent: nil
        ),
        TabModel(
            sessionSlot: 1,
            startURL: URL(string: "https://seatgeek.com")!,
            dataStore: .default(),
            proxyType: .local,
            authProxy: nil,
            userAgent: nil
        ),
        TabModel(
            sessionSlot: 2,
            startURL: URL(string: "https://ticketmaster.com")!,
            dataStore: .default(),
            proxyType: .local,
            authProxy: nil,
            userAgent: nil
        )
    ]

    state.selectedTabID = state.tabs.first?.id

    return BrowserChromeView(
        state: state,
        menu: .default
    )        { _ in }
    // .frame(width: 900, height: 80)
    // .padding()
    .background(AppBackgroundStyle.browserJetGradient.makeView())
    .environmentObject(sessionManager)
    .environment(\.appTheme, BrowserJetLightTheme())
}

#Preview {
    let sessionManager = SessionManager()
    let themeManager = ThemeManager()

    // Fake request
    let request = LaunchRequest(
        address: "https://www.google.com",
        numberOfTabs: 3,
        proxyType: .proxy(.builtIn(vpn: .vpn1, region: .uk)),
        isolationMode: .perTab,
        userAgent: nil
    )

    // Fake proxies
    let proxies: [AuthProxy] = [
        AuthProxy(host: "127.0.0.1", port: 8080, username: "u", password: "p")
    ]

    let state = BrowserWindowState(
        proxyType: request.proxyType,
        isolationMode: request.isolationMode,
        proxies: proxies,
        userAgent: request.userAgent,
        sessionManager: sessionManager,
        initialURL: URL(string: "https://www.google.com")!,
        initialTabCount: 2
    )

    return BrowserWindowView(state: state, request: request)
        .environmentObject(sessionManager)
        .environmentObject(themeManager)
        .environment(\.appTheme, BrowserJetLightTheme())
    // .padding()
        .background(AppBackgroundStyle.browserJetGradient.makeView())
}
