//
//  LicenseStore.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 24/02/2026.
//

import Foundation

final class LicenseStore {

    private let defaults: UserDefaults
    private let key = "com.browserjet.license"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - Public API

    func save(_ response: VerifyKeyResponse) {
        let model = PersistedLicense(response)
        guard let data = try? PropertyListEncoder().encode(model) else {
            AppLogger.error("LicenseStore: failed to encode license for persistence")
            return
        }
        defaults.set(data, forKey: key)
        AppLogger.info("LicenseStore: license saved for \(response.userEmail)")
    }

    func load() -> PersistedLicense? {
        guard let data = defaults.data(forKey: key),
              let model = try? PropertyListDecoder().decode(PersistedLicense.self, from: data) else {
            return nil
        }
        return model
    }

    func clear() {
        defaults.removeObject(forKey: key)
        AppLogger.info("LicenseStore: license cleared")
    }
}
