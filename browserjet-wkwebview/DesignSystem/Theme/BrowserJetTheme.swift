//
//  BrowserJetTheme.swift
//  browserjet-wkwebview
//
//  Created by Moiz Ul Hasan on 22/01/2026.
//

import SwiftUI

struct BrowserJetLightTheme: AppTheme {
    let appBackground: Color = Color(nsColor: .windowBackgroundColor)
    let elevatedBackground: Color = Color(nsColor: .controlBackgroundColor)
    let webBackground: Color = .white

    let textPrimary: Color = .primary
    let textSecondary: Color = .secondary

    let border: Color = Color(nsColor: .separatorColor)

    let accent: Color = .blue
    let destructive: Color = .red

    let badgeBackground: Color = Color.black.opacity(0.75)
    let badgeText: Color = .white
}

struct BrowserJetDarkTheme: AppTheme {
    let appBackground: Color = Color(nsColor: .windowBackgroundColor)
    let elevatedBackground: Color = Color(nsColor: .controlBackgroundColor)
    let webBackground: Color = Color(nsColor: .textBackgroundColor)

    let textPrimary: Color = .primary
    let textSecondary: Color = .secondary

    let border: Color = Color(nsColor: .separatorColor)

    let accent: Color = .blue
    let destructive: Color = .red

    let badgeBackground: Color = Color.white.opacity(0.12)
    let badgeText: Color = .white
}
