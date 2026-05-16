//
//  AppBackgroundStyle.swift
//  browserjet-wkwebview
//
//  Created by Moiz Ul Hasan on 10/02/2026.
//

import SwiftUI

enum AppBackgroundStyle {
    case browserJetGradient
    case browserJetDarkGradient
    case solid(Color)
}

extension AppBackgroundStyle {
    @ViewBuilder
    func makeView() -> some View {
        switch self {
        case .browserJetGradient:
            LinearGradient(
                colors: [
                    Color(red: 0.92, green: 0.96, blue: 1.00),
                    Color(red: 0.84, green: 0.92, blue: 1.00),
                    Color(red: 0.76, green: 0.88, blue: 1.00)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

        case .browserJetDarkGradient:
            LinearGradient(
                colors: [
                    Color(red: 0.055, green: 0.063, blue: 0.078),  // #0E1014
                    Color(red: 0.067, green: 0.075, blue: 0.082),  // #111315
                    Color(red: 0.086, green: 0.102, blue: 0.125)   // #161A20
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

        case .solid(let color):
            color
        }
    }

    /// Returns the brand gradient appropriate for the resolved color scheme.
    static func brandGradient(for colorScheme: ColorScheme) -> AppBackgroundStyle {
        colorScheme == .dark ? .browserJetDarkGradient : .browserJetGradient
    }
}

extension View {
    /// Paints the brand gradient as the window background, extends it under the
    /// (transparent) title bar, and bridges the resolved color scheme to the
    /// underlying `NSWindow` so AppKit chrome (traffic lights, etc.) tints to match.
    /// Pass the *resolved* scheme (i.e. honoring `ThemeManager.mode`), not the raw
    /// system `colorScheme`.
    func brandThemedWindow(for resolvedScheme: ColorScheme) -> some View {
        self
            .background(
                AppBackgroundStyle
                    .brandGradient(for: resolvedScheme)
                    .makeView()
                    .ignoresSafeArea(.all, edges: .top)
            )
            .preferredColorScheme(resolvedScheme)
    }
}
