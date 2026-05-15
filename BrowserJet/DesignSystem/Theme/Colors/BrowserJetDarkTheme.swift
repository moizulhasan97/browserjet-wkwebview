//
//  BrowserJetDarkTheme.swift
//  browserjet-wkwebview
//
//  Created by Moiz Ul Hasan on 10/02/2026.
//

import SwiftUI

struct BrowserJetDarkTheme: AppTheme {
    var surfaceCard: Color = .red
    var surfaceCardOverlay: Color = .red
    var surfaceControl: Color = .red
    var surfaceControlOverlay: Color = .red
    var strokeCard: Color = .red
    var strokeControl: Color = .red
    var divider: Color = .red
    var accentPressed: Color = .red
    var accentDisabled: Color = .red

    let appBackground = Color(nsColor: .windowBackgroundColor)
    let surfaceElevated = Color(nsColor: .controlBackgroundColor)
    let webBackground = Color(nsColor: .textBackgroundColor)

    let textPrimary = Color.primary
    let textFieldSecondary = Color.secondary
    let vpnConnection: Color = ._12_BF_2_C

    let border = Color(nsColor: .separatorColor)

    let accent = Color.blue
    let destructive = Color.red

    let badgeBackground = Color.white.opacity(0.12)
    let badgeText = Color.white

    let danger: Color = .E_5484_D
}
