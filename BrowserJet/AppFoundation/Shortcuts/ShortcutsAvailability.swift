//
//  ShortcutsAvailability.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 16/05/2026.
//

import Foundation

//  Single source of truth for whether keyboard shortcuts are active.
//  Combines the Firebase Remote Config kill-switch with per-window
//  trial/license gating.
@MainActor
enum ShortcutsAvailability {
    /// Shortcuts are enabled when:
    ///   1. Remote Config `shortcuts_enabled` is true (default true).
    ///   2. The window is NOT in trial-lock state (expired trial / failed payment).
    static func isAllowed(for state: BrowserWindowState?) -> Bool {
        guard let state else { return false }
        guard !state.isTrialLockActive else { return false }
        return RemoteConfigManager.shared.resolvedFeatureFlagsConfig.shortcutsEnabled
    }
}
