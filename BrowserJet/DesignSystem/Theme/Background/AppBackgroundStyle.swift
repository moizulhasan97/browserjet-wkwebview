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
                    Color(red: 0.055, green: 0.063, blue: 0.078),
                    Color(red: 0.067, green: 0.075, blue: 0.082),
                    Color(red: 0.086, green: 0.102, blue: 0.125)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
        case .solid(let color):
            color
        }
    }
    
    static func brandGradient(for colorScheme: ColorScheme) -> AppBackgroundStyle {
        colorScheme == .dark ? .browserJetDarkGradient : .browserJetGradient
    }
}

// MARK: - ThemeManager-driven windows (launcher, browser, settings, activation)

private struct BrandThemedWindowModifier: ViewModifier {
    @ObservedObject var themeManager: ThemeManager
    @Environment(\.colorScheme) private var colorScheme
    
    private var preferredScheme: ColorScheme? {
        switch themeManager.mode {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }
    
    func body(content: Content) -> some View {
        let resolved = themeManager.resolvedColorScheme(for: colorScheme)
        let background = AppBackgroundStyle
            .brandGradient(for: resolved)
            .makeView()
            .ignoresSafeArea()
        
        Group {
            if let preferredScheme {
                content
                    .background(background)
                    .preferredColorScheme(preferredScheme)
            } else {
                content.background(background)
            }
        }
        .id(themeManager.mode)
    }
}

// MARK: - System-following windows (About)

private struct SystemBrandThemedWindowModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    
    func body(content: Content) -> some View {
        content
            .background(
                AppBackgroundStyle
                    .brandGradient(for: colorScheme)
                    .makeView()
                    .ignoresSafeArea()
            )
    }
}

extension View {
    /// Brand gradient + color scheme. Re-renders when `themeManager.mode` changes.
    func brandThemedWindow(themeManager: ThemeManager) -> some View {
        modifier(BrandThemedWindowModifier(themeManager: themeManager))
    }
    
    /// About and other windows without a shared `ThemeManager`.
    func brandThemedWindow() -> some View {
        modifier(SystemBrandThemedWindowModifier())
    }
}
