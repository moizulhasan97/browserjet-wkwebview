//
//  BrowserJetLightTheme.swift
//  browserjet-wkwebview
//
//  Created by Moiz Ul Hasan on 10/02/2026.
//

import SwiftUI

struct BrowserJetLightTheme: AppTheme {
    let appBackground: Color = Color(nsColor: .windowBackgroundColor)
    let surfaceElevated: Color = Color(nsColor: .controlBackgroundColor)
    let webBackground: Color = .white

    let textPrimary: Color = .primary
    let textSecondary: Color = .secondary

    let border: Color = Color(nsColor: .separatorColor)

    let accent: Color = .blue
    let destructive: Color = .red

    let badgeBackground: Color = Color.black.opacity(0.75)
    let badgeText: Color = .white
}
