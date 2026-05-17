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
    enum Mode: String, Equatable, Hashable, CaseIterable {
        case system
        case light
        case dark

        var displayName: String {
            switch self {
            case .system: return "System"
            case .light: return "Light"
            case .dark: return "Dark"
            }
        }
    }

    @Published var mode: Mode {
        didSet {
            AppLogger.info("Theme mode changed to: \(mode)")
            ThemeWindowAppearance.apply(mode: mode)
        }
    }

    private let lightTheme: any AppTheme
    private let darkTheme: any AppTheme

    init(
        lightTheme: any AppTheme = BrowserJetLightTheme(),
        darkTheme: any AppTheme = BrowserJetDarkTheme(),
        keyValueStore: KeyValueStoring = UserDefaultsKeyValueStore()
    ) {
        AppLogger.debug("ThemeManager initializing with light and dark themes")
        self.lightTheme = lightTheme
        self.darkTheme = darkTheme
        self.mode = Self.loadPersistedMode(from: keyValueStore) ?? .light
        AppLogger.debug("ThemeManager initialized - Mode: \(mode)")
    }

    /// Call once `NSApp` is available (e.g. from `BrowserJet.init` on the main queue).
    func applyWindowAppearance() {
        ThemeWindowAppearance.apply(mode: mode)
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

    func resolvedColorScheme(for colorScheme: ColorScheme) -> ColorScheme {
        switch mode {
        case .system: return colorScheme
        case .light: return .light
        case .dark: return .dark
        }
    }

    private static func loadPersistedMode(from store: KeyValueStoring) -> Mode? {
        guard let raw = store.object(forKey: StorageKeys.appearanceMode) as? String else {
            return nil
        }
        return Mode(rawValue: raw)
    }
}
