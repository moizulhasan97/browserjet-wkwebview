//
//  BrowserJetLightTheme.swift
//  browserjet-wkwebview
//
//  Created by Moiz Ul Hasan on 10/02/2026.
//

import SwiftUI

struct BrowserJetLightTheme: AppTheme {
    // MARK: - Surfaces (Solid)
    let surfaceCard: Color = .white.opacity(0.96)
    let surfaceCardOverlay: Color = .clear

    let surfaceControl: Color = .init(red: 0.96, green: 0.98, blue: 0.99)
    let surfaceControlOverlay: Color = .clear

    // MARK: - Text
    let textPrimary: Color = .black.opacity(0.88)
    let textFieldSecondary: Color = ._4_C_4_C_4_C
    let vpnConnection: Color = ._12_BF_2_C

    // MARK: - Strokes / Dividers
    let strokeCard: Color = .init(red: 0.90, green: 0.94, blue: 0.97)
    let strokeControl: Color = .init(red: 0.85, green: 0.90, blue: 0.96)
    let divider: Color = .black.opacity(0.08)

    // MARK: - Actions
    let accent: Color = .init(red: 0.21, green: 0.52, blue: 0.96)
    let accentPressed: Color = .init(red: 0.15, green: 0.44, blue: 0.90)
    let accentDisabled: Color = .init(red: 0.21, green: 0.52, blue: 0.96).opacity(0.40)

    // MARK: - Badge
    let badgeBackground: Color = .black.opacity(0.70)
    let badgeText: Color = .white

    // MARK: - Error
    let danger: Color = .E_5484_D
}
