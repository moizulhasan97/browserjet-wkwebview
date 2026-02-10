//
//  BrowserJetDarkTheme.swift
//  browserjet-wkwebview
//
//  Created by Moiz Ul Hasan on 10/02/2026.
//

import SwiftUI

struct BrowserJetDarkTheme: AppTheme {
    let appBackground: Color = Color(nsColor: .windowBackgroundColor)
    let surfaceElevated: Color = Color(nsColor: .controlBackgroundColor)
    let webBackground: Color = Color(nsColor: .textBackgroundColor)

    let textPrimary: Color = .primary
    let textSecondary: Color = .secondary

    let border: Color = Color(nsColor: .separatorColor)

    let accent: Color = .blue
    let destructive: Color = .red

    let badgeBackground: Color = Color.white.opacity(0.12)
    let badgeText: Color = .white
}
