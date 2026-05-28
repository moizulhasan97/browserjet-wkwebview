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
    @Environment(\.appTheme)
    private var theme

    @State private var canScrollLeft: Bool = false
    @State private var canScrollRight: Bool = false
    @State private var scrollOffset: CGFloat = 0

    // MARK: - Layout Constants
    private let horizontalPadding: CGFloat = 12
    private let spacing: CGFloat = 6
    private let minTabWidth: CGFloat = 120
    private let maxTabWidth: CGFloat = 240
    private let stripHeight: CGFloat = 44
    private let fadeGradientWidth: CGFloat = 40

    var body: some View {
        GeometryReader { geometry in
            let availableWidth = max(0, geometry.size.width - (horizontalPadding * 2))
            let tabCount = max(state.tabs.count, 1)

            // Smart tab sizing: tabs shrink as count increases
            let rawWidth = availableWidth / CGFloat(tabCount)
            let calculatedWidth = min(maxTabWidth, max(minTabWidth, rawWidth))

            ZStack(alignment: .leading) {
                // Main scrollable tab area
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: spacing) {
                            ForEach(state.tabs) { tab in
                                BrowserTabPillView(
                                    tab: tab,
                                    isSelected: tab.id == state.selectedTabID,
                                    width: calculatedWidth,
                                    showCloseButton: true,
                                    isCloseDisabled: state.isTrialLockActive,
                                    onSelect: {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                            state.selectedTabID = tab.id
                                        }
                                        // Auto-scroll selected tab into view
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                            proxy.scrollTo(tab.id, anchor: .center)
                                        }
                                    },
                                    onClose: {
                                        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                                            state.requestCloseTab(tab.id)
                                        }
                                    }
                                )
                                .id(tab.id)
                                .transition(.asymmetric(
                                    insertion: .opacity
                                        .combined(with: .move(edge: .trailing))
                                        .combined(with: .scale(scale: 0.9)),
                                    removal: .opacity.combined(with: .scale(scale: 0.85))
                                ))
                            }
                        }
                        .padding(.horizontal, horizontalPadding)
                        .padding(.vertical, 8)
                        .background(
                            GeometryReader { contentGeometry in
                                Color.clear
                                    .preference(
                                        key: ContentWidthPreferenceKey.self,
                                        value: contentGeometry.size.width
                                    )
                                    .preference(
                                        key: ContentOffsetPreferenceKey.self,
                                        value: contentGeometry.frame(in: .named("scrollView")).minX
                                    )
                            }
                        )
                    }
                    .onPreferenceChange(ContentWidthPreferenceKey.self) { contentWidth in
                        updateScrollIndicators(geometry: geometry, contentWidth: contentWidth)
                    }
                    .onPreferenceChange(ContentOffsetPreferenceKey.self) { offset in
                        scrollOffset = offset
                        let contentWidth = calculatedWidth * CGFloat(tabCount) + horizontalPadding * 2
                        updateScrollIndicators(geometry: geometry, contentWidth: contentWidth)
                    }
                    .onChange(of: state.tabs.count) { _ in
                        // Auto-scroll to selected tab when tabs change
                        if let selectedID = state.selectedTabID {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    proxy.scrollTo(selectedID, anchor: .center)
                                }
                            }
                        }
                    }
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: state.tabs.count)
                }
            }
        }
        .frame(height: stripHeight)
    }

    private func updateScrollIndicators(geometry: GeometryProxy, contentWidth: CGFloat) {
        let scrollViewWidth = geometry.size.width
        let canScroll = contentWidth > scrollViewWidth

        withAnimation(.easeOut(duration: 0.2)) {
            canScrollLeft = canScroll && scrollOffset < -horizontalPadding + 10
            canScrollRight = canScroll && (scrollOffset + contentWidth) > (scrollViewWidth - horizontalPadding - 10)
        }
    }
}

// Preference keys for tracking scroll state
struct ContentWidthPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct ContentOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// swiftlint:disable force_unwrapping
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
// swiftlint:enable force_unwrapping
