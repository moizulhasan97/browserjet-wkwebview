//
//  BrowserTabPillView.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 16/02/2026.
//


import SwiftUI

// Type eraser for Shape protocol to allow conditional shape returns
struct AnyShape: Shape {
    private let _path: (CGRect) -> Path

    init<S: Shape>(_ shape: S) {
        _path = shape.path(in:)
    }

    func path(in rect: CGRect) -> Path {
        _path(rect)
    }
}

// Custom shape for selected tab: rounded top corners and slightly rounded bottom corners
struct SelectedTabShape: Shape {
    var topCornerRadius: CGFloat
    var bottomCornerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let topRadius = min(topCornerRadius, rect.width / 2, rect.height / 2)
        let bottomRadius = min(bottomCornerRadius, rect.width / 2, rect.height / 2)

        // Start from left side, just below top-left corner
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + topRadius))

        // Top-left rounded corner
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + topRadius, y: rect.minY),
            control: CGPoint(x: rect.minX, y: rect.minY)
        )

        // Top edge
        path.addLine(to: CGPoint(x: rect.maxX - topRadius, y: rect.minY))

        // Top-right rounded corner
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + topRadius),
            control: CGPoint(x: rect.maxX, y: rect.minY)
        )

        // Right edge (straight down to bottom-right corner)
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - bottomRadius))

        // Bottom-right rounded corner (for blend effect)
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - bottomRadius, y: rect.maxY),
            control: CGPoint(x: rect.maxX, y: rect.maxY)
        )

        // Bottom edge
        path.addLine(to: CGPoint(x: rect.minX + bottomRadius, y: rect.maxY))

        // Bottom-left rounded corner (for blend effect)
        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.maxY - bottomRadius),
            control: CGPoint(x: rect.minX, y: rect.maxY)
        )

        // Left edge (closes the path)
        path.closeSubpath()
        return path
    }
}

// Border shape for selected tab: only top and sides, no bottom
struct SelectedTabBorderShape: Shape {
    var topCornerRadius: CGFloat
    var bottomCornerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let topRadius = min(topCornerRadius, rect.width / 2, rect.height / 2)
        let bottomRadius = min(bottomCornerRadius, rect.width / 2, rect.height / 2)
        let lineWidth: CGFloat = 0.5

        // Start from left side, just below top-left corner
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + topRadius))

        // Top-left rounded corner
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + topRadius, y: rect.minY),
            control: CGPoint(x: rect.minX, y: rect.minY)
        )

        // Top edge
        path.addLine(to: CGPoint(x: rect.maxX - topRadius, y: rect.minY))

        // Top-right rounded corner
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + topRadius),
            control: CGPoint(x: rect.maxX, y: rect.minY)
        )

        // Right edge (straight down, but stop before bottom to avoid bottom border)
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - bottomRadius - lineWidth))

        // Left edge (straight up from bottom, connecting back to start)
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - bottomRadius - lineWidth))

        return path
    }
}

struct BrowserTabPillView: View {
    @Environment(\.appTheme)
    private var theme

    @ObservedObject var tab: TabModel
    let isSelected: Bool
    let width: CGFloat
    let onSelect: () -> Void
    let onClose: () -> Void

    @State private var isHovering: Bool = false

    // MARK: - Thresholds (tune freely)
    private let compactThreshold: CGFloat = 140      // below this: favicon-only
    private let showCloseThreshold: CGFloat = 120    // below this: hide close even when not hovering
    private let pillCornerRadius: CGFloat = 10       // Corner radius for all tabs

    var body: some View {
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
                closeButton
                    .transition(.opacity.combined(with: .scale(scale: 0.85)))
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
        .onTapGesture { onSelect() }
        .onHover { hovering in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isHovering = hovering
            }
        }
        .help(tab.title)
        .accessibilityLabel("Tab: \(tab.title)")
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovering)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isSelected)
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

    // MARK: - Styling

    private var titleColor: Color {
        if isSelected {
            return theme.textPrimary.opacity(0.95)
        } else {
            return theme.textPrimary.opacity(isHovering ? 0.8 : 0.65)
        }
    }

    private var background: some View {
        Group {
            if isSelected {
                // Selected tab: glass morphism effect with subtle gradient
                ZStack {
                    // Base glass effect
                    theme.surfaceCard.opacity(0.85)

                    // Subtle gradient overlay for depth
                    LinearGradient(
                        colors: [
                            theme.surfaceCard.opacity(0.9),
                            theme.surfaceCard.opacity(0.75)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
            } else {
                // Inactive tabs: subtle background with hover effect
                ZStack {
                    theme.surfaceCard.opacity(0.4)

                    if isHovering {
                        LinearGradient(
                            colors: [
                                theme.surfaceCard.opacity(0.6),
                                theme.surfaceCard.opacity(0.5)
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

    private var glowEffect: some View {
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

    private var shadowColor: Color {
        if isSelected {
            return theme.accent.opacity(0.12)
        } else if isHovering {
            return .black.opacity(0.08)
        } else {
            return .black.opacity(0.04)
        }
    }

    private var shadowRadius: CGFloat {
        if isSelected {
            return 8
        } else if isHovering {
            return 4
        } else {
            return 2
        }
    }

    private var shadowOffset: CGFloat {
        if isSelected {
            return 2
        } else {
            return 1
        }
    }

    private var border: some View {
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

    private var closeButton: some View {
        Button(
            action: {
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
                .scaleEffect(isHovering ? 1.1 : 1.0)
            }
        )
        .buttonStyle(.plain)
        .accessibilityLabel("Close tab \(tab.title)")
    }

    private var closeButtonColor: Color {
        if isSelected {
            return theme.textPrimary.opacity(isHovering ? 0.9 : 0.7)
        } else {
            return theme.textPrimary.opacity(isHovering ? 0.8 : 0.6)
        }
    }

    private var closeButtonBackground: some View {
        Group {
            if isHovering {
                theme.accent.opacity(0.15)
            } else {
                Color.clear
            }
        }
    }

    @ViewBuilder
    private var faviconOrLoader: some View {
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
