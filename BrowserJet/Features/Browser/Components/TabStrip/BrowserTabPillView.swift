//
//  BrowserTabPillView.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 16/02/2026.
//

import SwiftUI

struct BrowserTabPillView: View {
    @Environment(\.appTheme)
    private var theme

    @ObservedObject var tab: TabModel
    let isSelected: Bool
    let width: CGFloat
    let showCloseButton: Bool
    /// When true, close button is visible but disabled (grayed, no action).
    var isCloseDisabled: Bool = false
    let onSelect: () -> Void
    let onClose: () -> Void

    @State private var isHovering: Bool = false

    // MARK: - Thresholds (tune freely)
    private let compactThreshold: CGFloat = 140      // below this: favicon-only
    private let showCloseThreshold: CGFloat = 120    // below this: hide close even when not hovering
    private let pillCornerRadius: CGFloat = 10       // Corner radius for all tabs

    var body: some View {
        ZStack(alignment: .trailing) {
            selectButton

            if shouldShowClose {
                closeButton
                    .padding(.trailing, 12)
                    .transition(.opacity.combined(with: .scale(scale: 0.85)))
            }
        }
        .onHover { hovering in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isHovering = hovering
            }
        }
        .help(tab.title)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovering)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isSelected)
    }

    private var selectButton: some View {
        Button(action: onSelect) {
            HStack(spacing: 8) {
                faviconOrLoader

                if !isCompact {
                    Text(tab.title)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(titleColor)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }

                Spacer(minLength: 0)

                if shouldShowClose {
                    Color.clear
                        .frame(width: 16, height: 16)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(width: width, alignment: .leading)
            .background(background)
            .overlay(border)
            .overlay(glowEffect)
            .overlay(selectedIndicator)
            .clipShape(tabClipShape)
            .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: shadowOffset)
            .scaleEffect(isHovering && !isSelected ? 1.02 : 1.0)
            .zIndex(isSelected ? 2 : (isHovering ? 1 : 0))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Layout logic

    private var isCompact: Bool {
        width < compactThreshold
    }

    private var shouldShowClose: Bool {
        guard showCloseButton else { return false }
        // Chrome-ish:
        // - if very small -> only show close on selected tab (optional)
        // - otherwise show close on hover or if selected
        if width < showCloseThreshold {
            return isSelected && (isHovering || isCloseDisabled)
        }
        return isHovering || isSelected || isCloseDisabled
    }

    private var tabClipShape: AnyShape {
        // All tabs use the same rounded rectangle shape
        AnyShape(RoundedRectangle(cornerRadius: pillCornerRadius, style: .continuous))
    }

    private var selectedIndicator: some View {
        Group {
            if isSelected {
                // Elegant bottom indicator bar for selected tab
                VStack {
                    Spacer()
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    theme.accent.opacity(0.8),
                                    theme.accent.opacity(0.6)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 3)
                        .cornerRadius(1.5)
                }
            }
        }
    }
}

// MARK: - Styling
extension BrowserTabPillView {
    var titleColor: Color {
        if isSelected {
            return theme.textPrimary.opacity(0.95)
        } else {
            return theme.textPrimary.opacity(isHovering ? 0.8 : 0.65)
        }
    }

    var background: some View {
        Group {
            if isSelected {
                // Selected tab: elevated control surface with a subtle vertical sheen
                ZStack {
                    theme.surfaceControl

                    LinearGradient(
                        colors: [
                            theme.surfaceControl.opacity(0.0),
                            Color.white.opacity(0.04)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
            } else {
                // Inactive tabs: card surface, slightly lifted on hover
                ZStack {
                    theme.surfaceCard.opacity(isHovering ? 0.85 : 0.55)

                    if isHovering {
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.03),
                                Color.white.opacity(0.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .transition(.opacity)
                    }
                }
            }
        }
    }

    var glowEffect: some View {
        Group {
            if isSelected {
                // Subtle inner glow for selected tab
                RoundedRectangle(cornerRadius: pillCornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                theme.accent.opacity(0.2),
                                theme.accent.opacity(0.05),
                                theme.accent.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .blur(radius: 3)
                    .opacity(0.6)
            }
        }
    }

    var shadowColor: Color {
        if isSelected {
            return theme.accent.opacity(0.12)
        } else if isHovering {
            return .black.opacity(0.08)
        } else {
            return .black.opacity(0.04)
        }
    }

    var shadowRadius: CGFloat {
        if isSelected {
            return 8
        } else if isHovering {
            return 4
        } else {
            return 2
        }
    }

    var shadowOffset: CGFloat {
        if isSelected {
            return 2
        } else {
            return 1
        }
    }

    var border: some View {
        Group {
            if isSelected {
                // Selected tab: elegant border with gradient on all sides
                RoundedRectangle(cornerRadius: pillCornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                theme.strokeControl.opacity(0.4),
                                theme.accent.opacity(0.3),
                                theme.strokeControl.opacity(0.4)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round)
                    )
            } else {
                // Inactive tab: subtle border that intensifies on hover
                RoundedRectangle(cornerRadius: pillCornerRadius, style: .continuous)
                    .stroke(
                        theme.strokeControl.opacity(isHovering ? 0.35 : 0.25),
                        style: StrokeStyle(lineWidth: 0.5, lineCap: .round, lineJoin: .round)
                    )
            }
        }
    }

    var closeButton: some View {
        Button(
            action: {
                guard !isCloseDisabled else { return }
                withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
                    onClose()
                }
            },
            label: {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(closeButtonColor)
                    .frame(width: 16, height: 16)
                    .background(closeButtonBackground)
                    .clipShape(Circle())
                    .scaleEffect(isHovering && !isCloseDisabled ? 1.1 : 1.0)
            }
        )
        .buttonStyle(.plain)
        .disabled(isCloseDisabled)
        .opacity(isCloseDisabled ? 0.5 : 1)
    }

    var closeButtonColor: Color {
        if isCloseDisabled {
            return theme.textPrimary.opacity(0.45)
        }
        if isSelected {
            return theme.textPrimary.opacity(isHovering ? 0.9 : 0.7)
        } else {
            return theme.textPrimary.opacity(isHovering ? 0.8 : 0.6)
        }
    }

    var closeButtonBackground: some View {
        Group {
            if isCloseDisabled {
                Color.clear
            } else if isHovering {
                theme.accent.opacity(0.15)
            } else {
                Color.clear
            }
        }
    }

    @ViewBuilder var faviconOrLoader: some View {
        if tab.isLoading {
            ProgressView()
                .controlSize(.small)
                .frame(width: 16, height: 16)
                .scaleEffect(isSelected ? 1.0 : 0.9)
        } else if let img = tab.favicon {
            Image(nsImage: img)
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
                .clipShape(RoundedRectangle(cornerRadius: 3.5, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 3.5, style: .continuous)
                        .stroke(theme.strokeControl.opacity(0.2), lineWidth: 0.5)
                )
                .scaleEffect(isHovering && !isSelected ? 1.05 : 1.0)
        } else {
            RoundedRectangle(cornerRadius: 3.5, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            theme.strokeControl.opacity(0.5),
                            theme.strokeControl.opacity(0.3)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 16, height: 16)
                .overlay(
                    RoundedRectangle(cornerRadius: 3.5, style: .continuous)
                        .stroke(theme.strokeControl.opacity(0.3), lineWidth: 0.5)
                )
        }
    }
}
