//
//  ThemeManager.swift
//  browserjet-wkwebview
//
//  Created by Moiz Ul Hasan on 22/01/2026.
//

import AppKit
import SwiftUI

@MainActor
final class ThemeManager: ObservableObject {
    enum Mode: String, Equatable, Hashable, CaseIterable, Identifiable {
        case system
        case light
        case dark

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .system: return "System"
            case .light:  return "Light"
            case .dark:   return "Dark"
            }
        }
    }

    @Published private(set) var mode: Mode
    @Published private var previewMode: Mode?
    @Published private(set) var appearanceRevision = 0

    private let lightTheme: any AppTheme
    private let darkTheme: any AppTheme
    private let store: KeyValueStoring

    var activeMode: Mode {
        previewMode ?? mode
    }

    /// Stable view identity for themed roots; bumps on cancel/commit to refresh stuck `preferredColorScheme`.
    var appearanceIdentity: String {
        "\(mode.rawValue)-\(appearanceRevision)"
    }

    init(
        lightTheme: any AppTheme = BrowserJetLightTheme(),
        darkTheme: any AppTheme = BrowserJetDarkTheme(),
        store: KeyValueStoring = UserDefaultsKeyValueStore()
    ) {
        self.lightTheme = lightTheme
        self.darkTheme = darkTheme
        self.store = store

        if let raw = store.object(forKey: StorageKeys.appearanceMode) as? String,
            let saved = Mode(rawValue: raw) {
            self.mode = saved
        } else {
            self.mode = .system
        }
        AppLogger.debug("ThemeManager initialized - Mode: \(self.mode)")
    }

    /// Call once `NSApp` is available (e.g. from `BrowserJet.init` on the main queue).
    func applyWindowAppearance() {
        ThemeWindowAppearance.apply(mode: mode)
    }

    /// SwiftUI-only preview (colors / gradient). Avoids AppKit window rebuilds that reset radio pickers.
    func preview(_ mode: Mode) {
        previewMode = mode
    }

    func cancelPreview() {
        previewMode = nil
        ThemeWindowAppearance.apply(mode: mode)
        appearanceRevision += 1
    }

    func commit(_ mode: Mode) {
        self.mode = mode
        self.previewMode = nil
        store.set(mode.rawValue, forKey: StorageKeys.appearanceMode)
        ThemeWindowAppearance.apply(mode: mode)
        appearanceRevision += 1
        AppLogger.info("Theme mode committed: \(mode)")
    }

    func theme(for colorScheme: ColorScheme) -> any AppTheme {
        resolvedColorScheme(for: colorScheme) == .dark ? darkTheme : lightTheme
    }

    func resolvedColorScheme(for colorScheme: ColorScheme) -> ColorScheme {
        switch activeMode {
        case .system: return systemColorScheme()
        case .light:  return .light
        case .dark:   return .dark
        }
    }

    private func systemColorScheme() -> ColorScheme {
        guard let app = NSApp else { return .light }
        let best = app.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua])
        return best == .darkAqua ? .dark : .light
    }
}
