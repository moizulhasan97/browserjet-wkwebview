//
//  BrowserToolbarView.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 16/02/2026.
//


import SwiftUI

struct BrowserToolbarView: View {
    @Environment(\.appTheme) private var theme
    @State private var showingDuplicatePopover = false
    let actions: [BrowserToolbarAction]
    let onAction: (BrowserToolbarAction) -> Void

    @State private var hovering: BrowserToolbarAction?

    var body: some View {
        HStack(spacing: 10) {
            ForEach(actions, id: \.self) { action in
                Button {
                    if action == .duplicateToTabsMenu {
                            showingDuplicatePopover.toggle()
                        } else {
                            onAction(action)
                        }
                } label: {
//                    Image(systemName: action.systemImageName)
//                        .font(.system(size: 14, weight: .semibold))
//                        .foregroundStyle(theme.textPrimary)
//                        .frame(width: 28, height: 28)
//                        .background(background(for: action))
//                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
//                        .overlay(
//                            RoundedRectangle(cornerRadius: 8, style: .continuous)
//                                .stroke(border(for: action), lineWidth: 1)
//                        )
                    BrowserToolbarIconButtonStyle(
                        systemImageName: action.systemImageName,
                        tooltip: action.accessibilityTitle
                    )
                }
                .buttonStyle(.plain)
                .popover(
                    isPresented: Binding(
                        get: { showingDuplicatePopover && action == .duplicateToTabsMenu },
                        set: { showingDuplicatePopover = $0 }
                    ),
                    arrowEdge: .bottom
                ) {
                    DuplicateTabsPopoverView(
                        maxCount: 10,
                        onConfirm: { count in
                            print("Duplicate tab count selected:", count)
                            onAction(.duplicateToTabsMenu)
                        }
                    )
                }
                .accessibilityLabel(action.accessibilityTitle)
                .help(action.tooltip) // ✅ tooltip on hover (macOS)
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
