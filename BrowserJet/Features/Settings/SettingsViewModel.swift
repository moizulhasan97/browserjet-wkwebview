//
//  SettingsViewModel.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 16/05/2026.
//

import Combine
import SwiftUI

@MainActor
final class SettingsViewModel: ObservableObject {
    
    @Published private(set) var committedMode: ThemeManager.Mode
    @Published var draftMode: ThemeManager.Mode
    
    @Published private(set) var committedDefaultURL: String
    @Published var draftDefaultURL: String
    
    @Published private(set) var committedOpenBlankPage: Bool
    @Published var draftOpenBlankPage: Bool

    @Published private(set) var committedConfirmBeforeQuit: Bool
    @Published var draftConfirmBeforeQuit: Bool

    private let themeManager: ThemeManager
    private let store: KeyValueStoring
    private let urlPreferences: LauncherStartURLPreferences
    private let quitPreferences: QuitConfirmationPreferences

    var hasUnsavedChanges: Bool {
        draftMode != committedMode
        || draftDefaultURL != committedDefaultURL
        || draftOpenBlankPage != committedOpenBlankPage
        || draftConfirmBeforeQuit != committedConfirmBeforeQuit
    }
    
    var isDefaultURLFieldDisabled: Bool {
        draftOpenBlankPage
    }
    
    var canSave: Bool {
        if draftOpenBlankPage { return true }
        return !draftDefaultURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    init(
        themeManager: ThemeManager,
        store: KeyValueStoring = UserDefaultsKeyValueStore()
    ) {
        self.themeManager = themeManager
        self.store = store
        self.urlPreferences = LauncherStartURLPreferences(store: store)
        self.quitPreferences = QuitConfirmationPreferences(store: store)

        let current = themeManager.mode
        committedMode = current
        draftMode = current
        
        let url = urlPreferences.defaultStartURL
        committedDefaultURL = url
        draftDefaultURL = url
        
        let blank = urlPreferences.openBlankPage
        committedOpenBlankPage = blank
        draftOpenBlankPage = blank

        let confirmQuit = quitPreferences.confirmBeforeQuit
        committedConfirmBeforeQuit = confirmQuit
        draftConfirmBeforeQuit = confirmQuit
    }
    
    func applyDraft(_ mode: ThemeManager.Mode) {
        guard draftMode != mode else { return }
        draftMode = mode
        themeManager.mode = mode
    }
    
    func setDraftOpenBlankPage(_ value: Bool) {
        draftOpenBlankPage = value
    }

    func setDraftConfirmBeforeQuit(_ value: Bool) {
        draftConfirmBeforeQuit = value
    }

    func cancel() {
        draftMode = committedMode
        themeManager.mode = committedMode
        draftDefaultURL = committedDefaultURL
        draftOpenBlankPage = committedOpenBlankPage
        draftConfirmBeforeQuit = committedConfirmBeforeQuit
    }
    
    func save() {
        let urlPrefsChanged = draftDefaultURL != committedDefaultURL
            || draftOpenBlankPage != committedOpenBlankPage
        let previousEffectiveURL = LauncherStartURLPreferences.effectiveStartURL(
            openBlankPage: committedOpenBlankPage,
            defaultStartURL: committedDefaultURL,
            fallbackConfigurationURL: ""
        )
        let newEffectiveURL = LauncherStartURLPreferences.effectiveStartURL(
            openBlankPage: draftOpenBlankPage,
            defaultStartURL: draftOpenBlankPage
                ? LauncherStartURLPreferences.blankPageURL
                : draftDefaultURL,
            fallbackConfigurationURL: ""
        )

        store.set(draftMode.rawValue, forKey: StorageKeys.appearanceMode)
        committedMode = draftMode

        urlPreferences.save(
            openBlankPage: draftOpenBlankPage,
            defaultStartURL: draftOpenBlankPage
                ? LauncherStartURLPreferences.blankPageURL
                : draftDefaultURL
        )
        committedDefaultURL = draftDefaultURL
        committedOpenBlankPage = draftOpenBlankPage

        quitPreferences.save(confirmBeforeQuit: draftConfirmBeforeQuit)
        committedConfirmBeforeQuit = draftConfirmBeforeQuit

        if urlPrefsChanged {
            let payload = LauncherStartURLPreferencesSavePayload(
                newEffectiveURL: newEffectiveURL,
                previousEffectiveURL: previousEffectiveURL
            )
            NotificationCenter.default.post(
                name: .launcherStartURLPreferencesDidSave,
                object: nil,
                userInfo: [LauncherStartURLPreferences.savePayloadUserInfoKey: payload]
            )
        }

        AppLogger.info(
            """
            Settings saved — appearance: \(draftMode), openBlank: \(draftOpenBlankPage), \
            defaultURL: \(draftDefaultURL), confirmBeforeQuit: \(draftConfirmBeforeQuit)
            """
        )
    }
}
