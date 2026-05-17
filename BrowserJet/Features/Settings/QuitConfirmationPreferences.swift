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
    static func requestQuit() {
        NSApplication.shared.terminate(nil)
    }

    static func applicationShouldTerminate() -> NSApplication.TerminateReply {
        guard QuitConfirmationPreferences().confirmBeforeQuit else {
            return .terminateNow
        }

        let alert = NSAlert()
        alert.messageText = "Quit BrowserJet?"
        alert.informativeText = "Are you sure you want to quit BrowserJet?"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Quit")
        alert.addButton(withTitle: "Cancel")

        return alert.runModal() == .alertFirstButtonReturn ? .terminateNow : .terminateCancel
    }
}
