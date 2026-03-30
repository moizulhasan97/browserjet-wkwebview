//
//  UserDefaultsKeyValueStore.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 25/02/2026.
//

import Foundation


enum StorageKeys {
    static let licenseKey = "LicenseKey"
    static let userEmail = "UserEmail"
    static let launcherSettings = "LauncherSettings"
    static let updateKeyInDatabase = "UpdateKeyInDatabase"
}

protocol KeyValueStoring: AnyObject {
    func object(forKey key: String) -> Any?
    func set(_ value: Any?, forKey key: String)
    func removeObject(forKey key: String)
}

final class UserDefaultsKeyValueStore: KeyValueStoring {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func object(forKey key: String) -> Any? {
        defaults.object(forKey: key)
    }

    func set(_ value: Any?, forKey key: String) {
        defaults.set(value, forKey: key)
    }

    func removeObject(forKey key: String) {
        defaults.removeObject(forKey: key)
    }
}
