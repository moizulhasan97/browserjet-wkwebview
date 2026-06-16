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
    var onDuplicateTabs: ((Int) -> Void)?
    
    @Environment(\.appTheme)
    private var theme

    /// Aligns the leading edge of the chrome with the macOS traffic-light cluster.
    /// On a `.titled, .fullSizeContentView` window the red close button sits at
    /// roughly x=7…21pt (center ≈ 14pt). 14pt puts the back button's visible
    /// edge under the red light's center, matching Safari/Finder convention.
    /// The trailing edge mirrors it.
    private static let trafficLightAlignedInset: CGFloat = 14

    private var enabledToolbarActions: Set<BrowserToolbarAction>? {
        state.isTrialLockActive ? [.reload, .stop] : nil
    }
    
    private var visibleMoreMenuItems: [BrowserMoreMenuItem] {
        state.isTrialLockActive ? /*[.about] :*/ [] : menu.moreMenuItems
    }
    
    var body: some View {
        HStack(spacing: 10) {
            if let tab = state.selectedTab {
                LeadingToolbar(
                    tab: tab,
                    actions: menu.leading,
                    enabledActions: enabledToolbarActions,
                    onAction: onToolbarAction
                )

                BrowserAddressBarView(
                    tab: tab,
                    isLocked: state.isTrialLockActive,
                    focusToken: state.focusAddressBarToken
                )
                .frame(maxWidth: .infinity)
            } else {
                BrowserToolbarView(
                    actions: menu.leading,
                    enabledActions: enabledToolbarActions,
                    onAction: onToolbarAction
                )
            }
            
            BrowserConnectionBadgeView(proxyType: state.proxyType)
                .opacity(state.isTrialLockActive ? 0.6 : 1)
                .allowsHitTesting(false)
            
            HStack(spacing: 10) {
                BrowserToolbarView(
                    actions: menu.trailing,
                    enabledActions: enabledToolbarActions,
                    onAction: onToolbarAction,
                    onDuplicateTabs: onDuplicateTabs
                )
                BrowserMoreMenuView(
                    items: visibleMoreMenuItems,
                    isDisabled: false
                ) { item in
                    onMoreMenuSelect(item)
                }
            }
        }
        .padding(.top, 10)
        .padding(.bottom, 9)
        .padding(.horizontal, Self.trafficLightAlignedInset)
    }
}

/// Wraps the leading toolbar so it observes the selected tab's loading state
/// and swaps the `.reload` action for `.stop` while the page is loading.
private struct LeadingToolbar: View {
    @ObservedObject var tab: TabModel
    let actions: [BrowserToolbarAction]
    let enabledActions: Set<BrowserToolbarAction>?
    let onAction: (BrowserToolbarAction) -> Void

    private var resolvedActions: [BrowserToolbarAction] {
        guard tab.isLoading else { return actions }
        return actions.map { $0 == .reload ? .stop : $0 }
    }

    var body: some View {
        BrowserToolbarView(
            actions: resolvedActions,
            enabledActions: enabledActions,
            onAction: onAction
        )
    }
}

// swiftlint:disable force_unwrapping
#Preview("Browser Chrome – Light") {
    let sessionManager = SessionManager()
    
    let state = BrowserWindowState(
        proxyType: .local,
        isolationMode: .perTab,
        proxies: [],
        userAgent: nil,
        sessionManager: sessionManager,
        initialURL: URL(string: "https://google.com")!,
        initialTabCount: 2,
        maxBrowserTabs: 20
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
        onToolbarAction: { _ in },
        onMoreMenuSelect: { _ in }
    )
    .background(AppBackgroundStyle.browserJetGradient.makeView())
    .environmentObject(sessionManager)
    .environment(\.appTheme, BrowserJetLightTheme())
}
// swiftlint:enable force_unwrapping
