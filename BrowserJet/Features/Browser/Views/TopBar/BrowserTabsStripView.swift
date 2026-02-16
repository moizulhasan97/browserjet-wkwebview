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
    private let addButtonWidth: CGFloat = 110
    private let stripHeight: CGFloat = 42

    var body: some View {
        GeometryReader { geometry in
            let availableWidth = max(0, geometry.size.width - addButtonWidth - (horizontalPadding * 2))
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

                        addTabButton(proxy: proxy)
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

    // MARK: - Add Tab Button
    private func addTabButton(proxy: ScrollViewProxy) -> some View {
        Button {
            guard sessionManager.canCreateSession else { return }
            withAnimation(.easeInOut(duration: 0.22)) {
                state.addTab()
            }
            if let id = state.selectedTabID {
                withAnimation(.easeInOut(duration: 0.22)) {
                    proxy.scrollTo(id, anchor: .center)
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "plus")
                Text("New Session")
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(theme.textPrimary)
            .frame(width: addButtonWidth, height: 30)
            .background(theme.surfaceControl)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(theme.strokeControl.opacity(0.7), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(!sessionManager.canCreateSession)
        .opacity(sessionManager.canCreateSession ? 1 : 0.5)
    }
}
