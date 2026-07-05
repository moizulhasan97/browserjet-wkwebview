//
//  AnalyticsManager.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 05/07/2026.
//

import FirebaseAnalytics
import Foundation

final class AnalyticsManager: AnalyticsReporting {
    static let shared = AnalyticsManager()

    private init() {}

    func configure() {
        Analytics.setAnalyticsCollectionEnabled(true)
        AppLogger.info("AnalyticsManager configured - collection enabled")
    }

    func log(_ event: AnalyticsEvent) {
        Analytics.logEvent(event.name, parameters: event.parameters)
        AppLogger.debug("Analytics event logged: \(event.name)")
    }

    func setUserProperty(_ value: String?, forName name: String) {
        Analytics.setUserProperty(value, forName: name)
    }

    func setUserID(fromLicenseKey licenseKey: String?) {
        guard let licenseKey, !licenseKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            Analytics.setUserID(nil)
            return
        }
        Analytics.setUserID(licenseKey.sha256Prefix(16))
    }

    func applyRemoteFlag(enabled: Bool) {
        Analytics.setAnalyticsCollectionEnabled(enabled)
        AppLogger.info("AnalyticsManager: remote flag applied - collection enabled = \(enabled)")
    }
}
