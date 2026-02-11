//
//  GlassControl.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 11/02/2026.
//

import SwiftUI

struct GlassControl: ViewModifier {
    let theme: any AppTheme
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .frame(minHeight: DesignMetrics.fieldHeight)
            .padding(.horizontal, 14)
            .background(
                ZStack {
                    Rectangle().fill(.ultraThinMaterial)
                    Rectangle().fill(theme.surfaceControl).overlay(theme.surfaceControlOverlay)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(theme.strokeControl, lineWidth: DesignMetrics.controlStrokeWidth)
            )
    }
}

extension View {
    func glassControl(theme: any AppTheme,
                      cornerRadius: CGFloat = DesignMetrics.controlCornerRadius) -> some View {
        modifier(GlassControl(theme: theme, cornerRadius: cornerRadius))
    }
}
