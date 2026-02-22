//
//  ThemeManager.swift
//  browserjet-wkwebview
//
//  Created by Moiz Ul Hasan on 22/01/2026.
//

import SwiftUI
import Combine

@MainActor
final class ThemeManager: ObservableObject {
    enum Mode: Equatable {
        case system
        case light
        case dark
    }

    @Published var mode: Mode = .system {
        didSet {
            AppLogger.info("Theme mode changed to: \(mode)")
        }
    }

    private let lightTheme: any AppTheme
    private let darkTheme: any AppTheme

    init(
        lightTheme: any AppTheme = BrowserJetLightTheme(),
        darkTheme: any AppTheme = BrowserJetDarkTheme()
    ) {
        AppLogger.debug("ThemeManager initializing with light and dark themes")
        self.lightTheme = lightTheme
        self.darkTheme = darkTheme
        AppLogger.debug("ThemeManager initialized - Mode: \(mode)")
    }

    func theme(for colorScheme: ColorScheme) -> any AppTheme {
        switch mode {
        case .system:
            AppLogger.debug("Theme resolved: \(colorScheme == .dark ? "dark" : "light") (system)")
            return colorScheme == .dark ? darkTheme : lightTheme
        case .light:
            AppLogger.debug("Theme resolved: light (forced)")
            return lightTheme
        case .dark:
            AppLogger.debug("Theme resolved: dark (forced)")
            return darkTheme
        }
    }
}
