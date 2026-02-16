//
//  BrowserTabPillView.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 16/02/2026.
//


import SwiftUI

struct BrowserTabPillView: View {
    @Environment(\.appTheme) private var theme

    let tab: BrowserTabItem
    let isSelected: Bool
    let width: CGFloat
    let onSelect: () -> Void
    let onClose: () -> Void

    @State private var isHovering: Bool = false

    // MARK: - Thresholds (tune freely)
    private let compactThreshold: CGFloat = 140      // below this: favicon-only
    private let showCloseThreshold: CGFloat = 120    // below this: hide close even when not hovering
    private let pillCornerRadius: CGFloat = 14

    var body: some View {
        HStack(spacing: 8) {
            faviconOrLoader

            if !isCompact {
                Text(tab.title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(theme.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }

            Spacer(minLength: 0)

            if shouldShowClose {
                closeButton
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .frame(width: width, alignment: .leading)
        .background(background)
        .overlay(border)
        .clipShape(RoundedRectangle(cornerRadius: pillCornerRadius, style: .continuous))
        .contentShape(Rectangle())
        .onTapGesture { onSelect() }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.12)) {
                isHovering = hovering
            }
        }
        .help(tab.title) // macOS tooltip like Chrome
        .accessibilityLabel("Tab: \(tab.title)")
        .animation(.easeInOut(duration: 0.12), value: isHovering)
        .animation(.easeInOut(duration: 0.12), value: isSelected)
    }

    // MARK: - Layout logic

    private var isCompact: Bool {
        width < compactThreshold
    }

    private var shouldShowClose: Bool {
        // Chrome-ish:
        // - if very small -> only show close on selected tab (optional)
        // - otherwise show close on hover or if selected
        if width < showCloseThreshold {
            return isSelected && isHovering
        }
        return isHovering || isSelected
    }

    // MARK: - Styling

    private var background: some View {
        let base = isSelected ? theme.surfaceCard : theme.surfaceCard.opacity(0.75)
        return base
            .opacity(isHovering && !isSelected ? 0.92 : 1.0)
    }

    private var border: some View {
        RoundedRectangle(cornerRadius: pillCornerRadius, style: .continuous)
            .stroke(
                isSelected ? theme.strokeControl : theme.strokeControl.opacity(0.5),
                lineWidth: isSelected ? 1.5 : 1
            )
    }

    private var closeButton: some View {
        Button(action: onClose) {
            Image(systemName: "xmark")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(theme.textPrimary.opacity(isHovering ? 0.85 : 0.75))
                .frame(width: 18, height: 18)
                .background(theme.surfaceControl.opacity(isHovering ? 0.55 : 0.0))
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Close tab \(tab.title)")
    }

    @ViewBuilder
    private var faviconOrLoader: some View {
        if tab.isLoading {
            ProgressView()
                .controlSize(.small)
                .frame(width: 14, height: 14)
        } else if let img = tab.favicon {
            Image(nsImage: img)
                .resizable()
                .scaledToFit()
                .frame(width: 14, height: 14)
                .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
        } else {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(theme.strokeControl.opacity(0.6))
                .frame(width: 14, height: 14)
        }
    }
}
