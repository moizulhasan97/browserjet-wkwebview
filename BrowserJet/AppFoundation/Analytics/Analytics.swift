//
//  Analytics.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 05/07/2026.
//

import Foundation

protocol AnalyticsReporting {
    /// One-time setup. Call after `FirebaseApp.configure()`.
    func configure()

    /// Logs a typed analytics event.
    func log(_ event: AnalyticsEvent)

    /// Attaches a non-PII user property (e.g. license tier) to all subsequent events.
    func setUserProperty(_ value: String?, forName name: String)

    /// Associates events with the same non-PII identifier used for Crashlytics — a hash of the
    /// license key, trial or paid. The raw key is never sent to Firebase.
    func setUserID(fromLicenseKey licenseKey: String?)

    /// Applies a remote on/off decision after Remote Config has fetched.
    func applyRemoteFlag(enabled: Bool)
}
