//
//  ManagedProxyAccountIdentifying.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 07/07/2026.
//

protocol ManagedProxyAccountIdentifying {
    /// `nil` when no license key is stored yet (e.g. activation not complete).
    func currentAccountId() -> String?
}

/// Hashes the stored license key to derive their anonymized user IDs
struct LicenseKeyManagedProxyAccountIdentifier: ManagedProxyAccountIdentifying {
    private let keyValueStore: KeyValueStoring
    
    init(keyValueStore: KeyValueStoring = UserDefaultsKeyValueStore()) {
        self.keyValueStore = keyValueStore
    }
    
    func currentAccountId() -> String? {
        guard
            let rawKey = keyValueStore.object(forKey: StorageKeys.licenseKey) as? String,
            !rawKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else { return nil }
        
        return rawKey.sha256Prefix(32)
    }
}
