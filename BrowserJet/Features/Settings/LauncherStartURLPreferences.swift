//
//  LauncherStartURLPreferences.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 17/05/2026.
//

import Foundation

extension Notification.Name {
    /// Posted after Settings saves launcher start URL preferences.
    static let launcherStartURLPreferencesDidSave = Notification.Name("launcherStartURLPreferencesDidSave")
}

/// Payload for `launcherStartURLPreferencesDidSave`.
struct LauncherStartURLPreferencesSavePayload {
    let newEffectiveURL: String
    let previousEffectiveURL: String
}

/// UserDefaults-backed launcher start URL (Settings → General).
@MainActor
struct LauncherStartURLPreferences {
    static let blankPageURL = "about:blank"

    static let savePayloadUserInfoKey = "payload"

    private let store: KeyValueStoring

    init(store: KeyValueStoring = UserDefaultsKeyValueStore()) {
        self.store = store
    }

    var openBlankPage: Bool {
        store.object(forKey: StorageKeys.openBlankPage) as? Bool ?? false
    }

    var defaultStartURL: String {
        let raw = store.object(forKey: StorageKeys.defaultStartURL) as? String
        let trimmed = raw?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? Self.blankPageURL : trimmed
    }

    /// Value to prefill the launcher address field when it is empty.
    func effectiveStartURL(fallbackConfigurationURL: String) -> String {
        Self.effectiveStartURL(
            openBlankPage: openBlankPage,
            defaultStartURL: defaultStartURL,
            fallbackConfigurationURL: fallbackConfigurationURL
        )
    }

    static func effectiveStartURL(
        openBlankPage: Bool,
        defaultStartURL: String,
        fallbackConfigurationURL: String
    ) -> String {
        if openBlankPage {
            return blankPageURL
        }
        let saved = defaultStartURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if !saved.isEmpty {
            return saved
        }
        let fallback = fallbackConfigurationURL.trimmingCharacters(in: .whitespacesAndNewlines)
        return fallback.isEmpty ? blankPageURL : fallback
    }

    func save(openBlankPage: Bool, defaultStartURL: String) {
        store.set(openBlankPage, forKey: StorageKeys.openBlankPage)
        let trimmed = defaultStartURL.trimmingCharacters(in: .whitespacesAndNewlines)
        store.set(trimmed.isEmpty ? Self.blankPageURL : trimmed, forKey: StorageKeys.defaultStartURL)
    }
}
