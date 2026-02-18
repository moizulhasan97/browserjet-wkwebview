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

    let actions: [BrowserToolbarAction]
    let onAction: (BrowserToolbarAction) -> Void

    var body: some View {
        HStack(spacing: 10) {
            ForEach(actions, id: \.self) { action in
                Button {
                    onAction(action)
                } label: {
                    Image(systemName: action.systemImageName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(theme.textPrimary)
                        .frame(width: 28, height: 28)
                        .background(theme.surfaceControl.opacity(0.7))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(theme.strokeControl.opacity(0.8), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(action.accessibilityTitle)
            }
        }
    }
}

private extension BrowserToolbarAction {
    var systemImageName: String {
        switch self {
        case .back: return "chevron.left"
        case .forward: return "chevron.right"
        case .reload: return "arrow.clockwise"
        case .vpnIndicator: return "shield"
        case .favorites: return "star"
        case .newTab: return "plus.square.on.square"
        case .downloads: return "arrow.down.circle"
        case .history: return "clock"
        case .settings: return "slider.horizontal.3"
        }
    }

    var accessibilityTitle: String {
        switch self {
        case .back: return "Back"
        case .forward: return "Forward"
        case .reload: return "Reload"
        case .vpnIndicator: return "Connection"
        case .favorites: return "Favorites"
        case .newTab: return "New Tab"
        case .downloads: return "Downloads"
        case .history: return "History"
        case .settings: return "Settings"
        }
    }
}
