//
//  CrashReportingManager.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 05/07/2026.
//

import Foundation
import FirebaseCrashlytics

final class CrashReportingManager: CrashReporting {
    static let shared = CrashReportingManager()

    private let crashlytics: Crashlytics

    private init() {
        crashlytics = Crashlytics.crashlytics()
    }

    func configure() {
        crashlytics.setCrashlyticsCollectionEnabled(true)
        setCustomValue(AppEnvironment.current.displayName, forKey: CustomKey.environment)
        setCustomValue(AppUtils.getAppMarketingVersion(), forKey: CustomKey.appVersion)
        setCustomValue(AppUtils.getAppBuildVersion(), forKey: CustomKey.buildNumber)
        AppLogger.info("CrashReportingManager configured - collection enabled")
    }

    func record(error: Error) {
        crashlytics.record(error: error)
        AppLogger.error("Non-fatal recorded: \(error.localizedDescription)")
    }

    func log(_ message: String) {
        crashlytics.log(message)
    }

    func setCustomValue(_ value: Any?, forKey key: String) {
        crashlytics.setCustomValue(value, forKey: key)
    }

    func setUserID(_ userID: String?) {
        crashlytics.setUserID(userID ?? "")
    }

    func checkForUnsentReports(completion: @escaping (Bool) -> Void) {
        crashlytics.checkForUnsentReports { hasReports in
            completion(hasReports)
        }
    }

    func sendUnsentReports() {
        crashlytics.sendUnsentReports()
    }
    
    func applyRemoteFlag(enabled: Bool) {
        crashlytics.setCrashlyticsCollectionEnabled(enabled)
        AppLogger.info("CrashReportingManager: remote flag applied - collection enabled = \(enabled)")
    }
}

extension CrashReportingManager {
    /// Custom-key names, centralized so call sites don't hardcode strings.
    enum CustomKey {
        static let environment = "app_environment"
        static let appVersion = "app_version"
        static let buildNumber = "build_number"
        static let sessionIsolationMode = "session_isolation_mode"
        static let activeVPNType = "active_vpn_type"
        static let openTabCount = "open_tab_count"
        static let openWindowCount = "open_window_count"
    }
}
