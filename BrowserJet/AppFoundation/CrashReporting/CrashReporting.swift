//
//  CrashReporting.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 05/07/2026.
//

import Foundation

protocol CrashReporting {
    /// One-time setup
    func configure()

    /// Records a non-fatal error so it shows up in the dashboard instead of failing silently.
    func record(error: Error)

    /// Adds a breadcrumb line to the timeline leading up to the next crash or non-fatal.
    func log(_ message: String)

    /// Attaches a custom key/value to all subsequent crash and non-fatal reports.
    func setCustomValue(_ value: Any?, forKey key: String)

    /// Associates reports with a non-PII identifier (hashed license key or anonymous install ID).
    func setUserID(_ userID: String?)

    /// Reports whether an unsent report exists from a previous session.
    func checkForUnsentReports(completion: @escaping (Bool) -> Void)

    /// Forces any pending unsent report to be sent immediately.
    func sendUnsentReports()
    
    /// Applies a remote on/off decision after Remote Config has fetched
    func applyRemoteFlag(enabled: Bool)
}
