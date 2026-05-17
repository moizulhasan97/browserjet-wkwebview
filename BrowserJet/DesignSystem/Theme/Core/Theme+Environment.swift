//
//  Theme+Environment.swift
//  browserjet-wkwebview
//
//  Created by Moiz Ul Hasan on 22/01/2026.
//

import SwiftUI

private struct ThemeKey: EnvironmentKey {
    static nonisolated(unsafe) let defaultValue: any AppTheme = BrowserJetLightTheme()
}

extension EnvironmentValues {
    var appTheme: any AppTheme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

extension View {
    /// Single place to inject semantic theme, design system, window gradient, and force refresh on mode change.
    func browserJetThemedRoot(
        themeManager: ThemeManager,
        colorScheme: ColorScheme
    ) -> some View {
        environment(\.appTheme, themeManager.theme(for: colorScheme))
            .environment(\.designSystem, DesignSystem())
            .brandThemedWindow(themeManager: themeManager)
            .id(themeManager.mode)
    }
}
