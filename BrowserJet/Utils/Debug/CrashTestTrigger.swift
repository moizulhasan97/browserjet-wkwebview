//
//  CrashTestTrigger.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 05/07/2026.
//

import Foundation

/// QA-only hook to validate the full Crashlytics pipeline: crash -> relaunch -> dashboard.
/// Only ever wired into UI behind `#if DEBUG` — never compiled into Release builds.
enum CrashTestTrigger {
    static func forceCrash() {
        AppLogger.info("CrashTestTrigger: forcing test crash")
        fatalError("BrowserJet manual Crashlytics test crash - safe to ignore in dashboards")
    }
    
    static func recordTestNonFatal() {
        CrashReportingManager.shared.record(error: AppError.custom("Manual Crashlytics non-fatal test"))
        AppLogger.info("CrashTestTrigger: recorded test non-fatal")
    }
}
