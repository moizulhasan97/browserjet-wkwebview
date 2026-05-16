//
//  BrowserJetDarkTheme.swift
//  browserjet-wkwebview
//
//  Created by Moiz Ul Hasan on 10/02/2026.
//

import SwiftUI

struct BrowserJetDarkTheme: AppTheme {
    // MARK: - Surfaces (Solid)
    let surfaceCard: Color = .init(red: 0.118, green: 0.133, blue: 0.165)        // #1E222A
    let surfaceCardOverlay: Color = .clear

    let surfaceControl: Color = .init(red: 0.141, green: 0.165, blue: 0.200)     // #242A33
    let surfaceControlOverlay: Color = .clear

    // MARK: - Text
    let textPrimary: Color = .init(red: 0.961, green: 0.969, blue: 0.980)        // #F5F7FA
    let textFieldSecondary: Color = .init(red: 0.608, green: 0.639, blue: 0.686) // #9BA3AF
    let vpnConnection: Color = ._12_BF_2_C

    // MARK: - Strokes / Dividers
    let strokeCard: Color = .white.opacity(0.06)
    let strokeControl: Color = .white.opacity(0.10)
    let divider: Color = .white.opacity(0.06)

    // MARK: - Actions
    let accent: Color = .init(red: 0.231, green: 0.510, blue: 0.965)             // #3B82F6
    let accentPressed: Color = .init(red: 0.145, green: 0.388, blue: 0.922)      // #2563EB
    let accentDisabled: Color = .init(red: 0.231, green: 0.510, blue: 0.965).opacity(0.40)

    // MARK: - Badge
    let badgeBackground: Color = .white.opacity(0.12)
    let badgeText: Color = .white

    // MARK: - Error
    let danger: Color = .E_5484_D
}
