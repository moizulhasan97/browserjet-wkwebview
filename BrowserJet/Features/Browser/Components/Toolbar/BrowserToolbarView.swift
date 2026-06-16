//
//  BrowserToolbarView.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 16/02/2026.
//

import SwiftUI

struct BrowserToolbarView: View {
    @Environment(\.appTheme)
    private var theme
    @State private var showingDuplicatePopover = false
    let actions: [BrowserToolbarAction]
    /// When non-nil, only these actions are enabled; others are visually disabled.
    var enabledActions: Set<BrowserToolbarAction>?
    let onAction: (BrowserToolbarAction) -> Void
    /// Called when the user confirms a duplicate-tabs count from the popover.
    var onDuplicateTabs: ((Int) -> Void)?

    @State private var hovering: BrowserToolbarAction?

    private func isActionEnabled(_ action: BrowserToolbarAction) -> Bool {
        guard let allowed = enabledActions else { return true }
        return allowed.contains(action)
    }

    var body: some View {
        HStack(spacing: 10) {
            ForEach(actions, id: \.self) { action in
                Button {
                    guard isActionEnabled(action) else { return }
                    if action == .duplicateToTabsMenu {
                        showingDuplicatePopover.toggle()
                    } else {
                        onAction(action)
                    }
                } label: {
                    BrowserToolbarIconButtonStyle(
                        systemImageName: action.systemImageName,
                        tooltip: action.accessibilityTitle
                    )
                }
                .buttonStyle(.plain)
                .disabled(!isActionEnabled(action))
                .opacity(isActionEnabled(action) ? 1 : 0.5)
                .popover(
                    isPresented: Binding(
                        get: { showingDuplicatePopover && action == .duplicateToTabsMenu },
                        set: { showingDuplicatePopover = $0 }
                    ),
                    arrowEdge: .bottom
                ) {
                    DuplicateTabsPopoverView { count in
                        showingDuplicatePopover = false
                        onDuplicateTabs?(count)
                    }
                }
                .accessibilityLabel(action.accessibilityTitle)
                .help(action.tooltip)
                .onHover { isHovering in
                    withAnimation(.easeInOut(duration: 0.12)) {
                        hovering = isHovering ? action : (hovering == action ? nil : hovering)
                    }
                }
            }
        }
    }

    private func background(for action: BrowserToolbarAction) -> Color {
        let isHover = hovering == action
        return theme.surfaceControl.opacity(isHover ? 0.95 : 0.7)
    }

    private func border(for action: BrowserToolbarAction) -> Color {
        let isHover = hovering == action
        return theme.strokeControl.opacity(isHover ? 1.0 : 0.8)
    }
}
