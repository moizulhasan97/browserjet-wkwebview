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

    var body: some View {
        HStack(spacing: 12) {

            BrowserConnectionBadgeView(title: state.connectionStatusTitle)

            BrowserTabsStripView(state: state)
                .frame(maxWidth: .infinity)

            BrowserToolbarView(
                actions: menu.trailing,
                onAction: onToolbarAction
            )
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(theme.surfaceCard.opacity(0.65))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(theme.divider),
            alignment: .bottom
        )
    }
}

#Preview("Browser Chrome – Light") {

    let sessionManager = SessionManager()

    let state = BrowserWindowState(
        proxyType: .local,
        isolationMode: .perTab,
        proxies: [],
        userAgent: nil,
        sessionManager: sessionManager
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
        onToolbarAction: { _ in }
    )
    .frame(width: 900, height: 80)
    .padding()
    .background(AppBackgroundStyle.browserJetGradient.makeView())
    .environmentObject(sessionManager)
    .environment(\.appTheme, BrowserJetLightTheme())
}
