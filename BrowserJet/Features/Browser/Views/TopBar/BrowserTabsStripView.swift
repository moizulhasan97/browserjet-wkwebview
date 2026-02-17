//
//  BrowserTabsStripView.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 16/02/2026.
//

import SwiftUI

struct BrowserTabsStripView: View {
    
    @ObservedObject var state: BrowserWindowState
    @EnvironmentObject private var sessionManager: SessionManager
    @Environment(\.appTheme) private var theme
    
    // MARK: - Layout Constants
    private let horizontalPadding: CGFloat = 10
    private let spacing: CGFloat = 8
    private let minTabWidth: CGFloat = 110
    private let maxTabWidth: CGFloat = 220
    //private let addButtonWidth: CGFloat = 110
    private let stripHeight: CGFloat = 42
    
    var body: some View {
        GeometryReader { geometry in
            let availableWidth = max(0, geometry.size.width - (horizontalPadding * 2))
            let tabCount = max(state.tabItems.count, 1)
            
            // Chrome-ish: tabs shrink as count increases
            let rawWidth = availableWidth / CGFloat(tabCount)
            let calculatedWidth = min(maxTabWidth, max(minTabWidth, rawWidth))
            
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: spacing) {
                        ForEach(state.tabItems) { tab in
                            BrowserTabPillView(
                                tab: tab,
                                isSelected: tab.id == state.selectedTabID,
                                width: calculatedWidth,
                                onSelect: {
                                    withAnimation(.easeInOut(duration: 0.18)) {
                                        state.selectedTabID = tab.id
                                    }
                                    // Optional: auto-scroll selected tab into view
                                    withAnimation(.easeInOut(duration: 0.22)) {
                                        proxy.scrollTo(tab.id, anchor: .center)
                                    }
                                },
                                onClose: {
                                    withAnimation(.easeInOut(duration: 0.20)) {
                                        state.closeTab(tab.id)
                                    }
                                }
                            )
                            .id(tab.id)
                            // Smooth width changes + selection transitions
                            .animation(.easeInOut(duration: 0.18), value: calculatedWidth)
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .trailing)),
                                removal: .opacity.combined(with: .scale(scale: 0.92))
                            ))
                        }
                    }
                    .padding(.horizontal, horizontalPadding)
                    .padding(.vertical, 6)
                }
                .animation(.easeInOut(duration: 0.22), value: state.tabItems)
            }
        }
        .frame(height: stripHeight)
        .background(theme.surfaceCard)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(theme.divider),
            alignment: .bottom
        )
    }
}

#Preview("BrowserTabsStripView") {
    let themeManager = ThemeManager()
    let sessionManager = SessionManager(maxSessions: 10)
    
    // Fake a BrowserWindowState with a few tabs
    let state = BrowserWindowState(
        proxyType: .local,
        isolationMode: .perTab,
        proxies: [],
        userAgent: nil,
        sessionManager: sessionManager,
        initialURL: URL(string: "https://www.google.com")!,
        initialTabCount: 2
    )
    
    // Add a few more tabs so we can see shrinking behavior
    state.addTab(url: URL(string: "https://www.google.com")!)
    state.addTab(url: URL(string: "https://seatgeek.com")!)
    state.addTab(url: URL(string: "https://ticketmaster.com")!)
    state.addTab(url: URL(string: "https://apple.com")!)
    state.addTab(url: URL(string: "https://github.com")!)
    
    // Optional: set a selected tab
    state.selectedTabID = state.tabs.first?.id
    
    return BrowserTabsStripView(state: state)
        .frame(width: 900, height: 42)
        .padding()
        .background(AppBackgroundStyle.browserJetGradient.makeView())
        .environmentObject(sessionManager)
        .environmentObject(themeManager)
        .environment(\.appTheme, BrowserJetLightTheme())
}
