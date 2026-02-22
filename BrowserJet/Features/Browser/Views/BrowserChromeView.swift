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
    let onMoreMenuSelect: (BrowserMoreMenuItem) -> Void
    var onDuplicateTabs: ((Int) -> Void)? = nil
    
    @Environment(\.appTheme)
    private var theme

    var body: some View {
        HStack(spacing: 10) {
            BrowserToolbarView(
                actions: menu.leading,
                onAction: onToolbarAction
            )

            if let tab = state.selectedTab {
                BrowserAddressBarView(tab: tab)
                    .frame(maxWidth: .infinity)
            }

            BrowserConnectionBadgeView(proxyType: state.proxyType)


            
            HStack(spacing: 10) {
                BrowserToolbarView(
                    actions: menu.trailing,
                    onAction: onToolbarAction,
                    onDuplicateTabs: onDuplicateTabs
                )
                BrowserMoreMenuView(items: menu.moreMenuItems) { item in
                    onMoreMenuSelect(item)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// swiftlint:disable all
#Preview("Browser Chrome – Light") {
    let sessionManager = SessionManager()

    let state = BrowserWindowState(
        proxyType: .local,
        isolationMode: .perTab,
        proxies: [],
        userAgent: nil,
        sessionManager: sessionManager,
        // swiftlint:disable:next force_unwrapping
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
        menu: .default,
        onToolbarAction: {_ in},
        onMoreMenuSelect: {_ in}
    )
    .background(AppBackgroundStyle.browserJetGradient.makeView())
    .environmentObject(sessionManager)
    .environment(\.appTheme, BrowserJetLightTheme())
}
