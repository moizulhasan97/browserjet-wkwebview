//
//  QuitConfirmationPreferences.swift
//  BrowserJet
//

import AppKit
import Foundation

/// UserDefaults-backed preference for whether to confirm before quitting.
@MainActor
struct QuitConfirmationPreferences {
    /// When `true`, the user is asked to confirm before BrowserJet quits.
    var confirmBeforeQuit: Bool {
        get {
            guard let stored = store.object(forKey: StorageKeys.confirmBeforeQuit) as? Bool else {
                return true
            }
            return stored
        }
        nonmutating set {
            store.set(newValue, forKey: StorageKeys.confirmBeforeQuit)
        }
    }
    
    private let store: KeyValueStoring
    
    init(store: KeyValueStoring = UserDefaultsKeyValueStore()) {
        self.store = store
    }
    
    func save(confirmBeforeQuit: Bool) {
        store.set(confirmBeforeQuit, forKey: StorageKeys.confirmBeforeQuit)
    }
}

@MainActor
enum QuitConfirmationController {
    /// Set when quit was already confirmed (e.g. closing the last window) or must not be confirmed (relaunch, license enforcement).
    private static var skipNextTerminationConfirmation = false
    
    /// User-initiated quit (⌘Q, last tab ⌘W, etc.) — respects "Confirm before quitting".
    static func requestQuit() {
        NSApplication.shared.terminate(nil)
    }
    
    /// Quit without the settings dialog (relaunch, MAC mismatch, key expired, force update).
    static func terminateWithoutConfirmation() {
        skipNextTerminationConfirmation = true
        NSApplication.shared.terminate(nil)
    }
    
    /// Called from `windowShouldClose` when closing would leave no visible windows.
    /// Returns `true` if the window may close; `false` if the user cancelled (window stays open).
    static func confirmClosingLastWindow() -> Bool {
        guard QuitConfirmationPreferences().confirmBeforeQuit else {
            return true
        }
        guard showQuitAlert() else {
            return false
        }
        skipNextTerminationConfirmation = true
        return true
    }
    
    static func applicationShouldTerminate() -> NSApplication.TerminateReply {
        if skipNextTerminationConfirmation {
            skipNextTerminationConfirmation = false
            return .terminateNow
        }
        guard QuitConfirmationPreferences().confirmBeforeQuit else {
            return .terminateNow
        }
        return showQuitAlert() ? .terminateNow : .terminateCancel
    }
    
    @discardableResult
    private static func showQuitAlert() -> Bool {
        let alert = NSAlert()
        alert.messageText = "Quit BrowserJet?"
        alert.informativeText = "Are you sure you want to quit BrowserJet?"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Quit")
        alert.addButton(withTitle: "Cancel")
        return alert.runModal() == .alertFirstButtonReturn
    }
}
