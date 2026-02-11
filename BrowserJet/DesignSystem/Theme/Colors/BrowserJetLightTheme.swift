//
//  BrowserJetLightTheme.swift
//  browserjet-wkwebview
//
//  Created by Moiz Ul Hasan on 10/02/2026.
//

import SwiftUI

/// Light-only for now. Dark can come later from designer.
struct BrowserJetLightTheme: AppTheme {
    // MARK: - Surfaces (Glass)
    let surfaceCard: Color = Color.white.opacity(0.55)
    let surfaceCardOverlay: Color = Color.white.opacity(0.18)

    let surfaceControl: Color = Color.white.opacity(0.75)
    let surfaceControlOverlay: Color = Color.white.opacity(0.22)

    // MARK: - Text
    let textPrimary: Color = Color.black.opacity(0.88)
    let textSecondary: Color = Color.black.opacity(0.60)
    let textMuted: Color = Color.black.opacity(0.42)
    let textOnAccent: Color = Color.white.opacity(0.95)

    // MARK: - Strokes / Dividers
    let strokeCard: Color = Color.white.opacity(0.55)
    let strokeControl: Color = Color.black.opacity(0.10)
    let divider: Color = Color.black.opacity(0.08)

    // MARK: - Actions
    let accent: Color = Color(red: 0.21, green: 0.52, blue: 0.96)          // launch button blue
    let accentPressed: Color = Color(red: 0.15, green: 0.44, blue: 0.90)
    let accentDisabled: Color = Color(red: 0.21, green: 0.52, blue: 0.96).opacity(0.40)

    // MARK: - Badge
    let badgeBackground: Color = Color.black.opacity(0.70)
    let badgeText: Color = Color.white
}
