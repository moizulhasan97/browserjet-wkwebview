//
//  GlassCard.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 11/02/2026.
//

import SwiftUI

struct GlassCard: ViewModifier {
    let theme: any AppTheme
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // macOS/iOS-style material
                    Rectangle()
                        .fill(.ultraThinMaterial)

                    // tint overlay (keeps it consistent across screens)
                    Rectangle()
                        .fill(theme.surfaceCard)
                        .overlay(theme.surfaceCardOverlay)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(theme.strokeCard, lineWidth: DesignMetrics.cardStrokeWidth)
            )
            .shadow(color: Color.black.opacity(0.08),
                    radius: DesignMetrics.cardShadowRadius,
                    x: 0,
                    y: DesignMetrics.cardShadowY)
    }
}

extension View {
    func glassCard(theme: any AppTheme,
                   cornerRadius: CGFloat = DesignMetrics.cardCornerRadius) -> some View {
        modifier(GlassCard(theme: theme, cornerRadius: cornerRadius))
    }
}
