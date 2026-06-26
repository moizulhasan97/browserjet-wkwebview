//
//  BrowserToolbarView.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 16/02/2026.
//

import SwiftUI

struct ToolbarButtonDescriptor: Hashable {
    let action: BrowserToolbarAction
    let tooltip: String

    init(action: BrowserToolbarAction, tooltip: String? = nil) {
        self.action = action
        self.tooltip = tooltip ?? action.tooltip
    }

    init(entry: TrailingToolbarEntry) {
        action = entry.action
        tooltip = entry.tooltip
    }
}

struct BrowserToolbarView: View {
    @Environment(\.appTheme)
    private var theme
    @State private var showingDuplicatePopover = false
    let buttons: [ToolbarButtonDescriptor]
    /// When non-nil, only these actions are enabled; others are visually disabled.
    var enabledActions: Set<BrowserToolbarAction>?
    let onAction: (BrowserToolbarAction) -> Void
    /// Called when the user confirms a duplicate-tabs count from the popover.
    var onDuplicateTabs: ((Int) -> Void)?

    @State private var hovering: BrowserToolbarAction?

    init(
        actions: [BrowserToolbarAction],
        enabledActions: Set<BrowserToolbarAction>? = nil,
        onAction: @escaping (BrowserToolbarAction) -> Void,
        onDuplicateTabs: ((Int) -> Void)? = nil
    ) {
        buttons = actions.map { ToolbarButtonDescriptor(action: $0) }
        self.enabledActions = enabledActions
        self.onAction = onAction
        self.onDuplicateTabs = onDuplicateTabs
    }

    init(
        entries: [TrailingToolbarEntry],
        enabledActions: Set<BrowserToolbarAction>? = nil,
        onAction: @escaping (BrowserToolbarAction) -> Void,
        onDuplicateTabs: ((Int) -> Void)? = nil
    ) {
        buttons = entries.map(ToolbarButtonDescriptor.init(entry:))
        self.enabledActions = enabledActions
        self.onAction = onAction
        self.onDuplicateTabs = onDuplicateTabs
    }

    private func isActionEnabled(_ action: BrowserToolbarAction) -> Bool {
        guard let allowed = enabledActions else { return true }
        return allowed.contains(action)
    }

    var body: some View {
        HStack(spacing: 10) {
            ForEach(buttons, id: \.action) { button in
                Button {
                    guard isActionEnabled(button.action) else { return }
                    if button.action == .duplicateToTabsMenu {
                        showingDuplicatePopover.toggle()
                    } else {
                        onAction(button.action)
                    }
                } label: {
                    BrowserToolbarIconButtonStyle(
                        systemImageName: button.action.systemImageName,
                        tooltip: button.tooltip
                    )
                }
                .buttonStyle(.plain)
                .disabled(!isActionEnabled(button.action))
                .opacity(isActionEnabled(button.action) ? 1 : 0.5)
                .popover(
                    isPresented: Binding(
                        get: { showingDuplicatePopover && button.action == .duplicateToTabsMenu },
                        set: { showingDuplicatePopover = $0 }
                    ),
                    arrowEdge: .bottom
                ) {
                    DuplicateTabsPopoverView { count in
                        showingDuplicatePopover = false
                        onDuplicateTabs?(count)
                    }
                }
                .accessibilityLabel(button.tooltip)
                .help(button.tooltip)
                .onHover { isHovering in
                    withAnimation(.easeInOut(duration: 0.12)) {
                        hovering = isHovering ? button.action : (hovering == button.action ? nil : hovering)
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
