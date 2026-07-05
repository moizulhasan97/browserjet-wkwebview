//
//  SparkleUpdaterDelegate.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 28/04/2026.
//

import Foundation
import Sparkle

final class SparkleUpdaterDelegate: NSObject, SPUUpdaterDelegate {
    // MARK: - Update cycle

    func updater(_ updater: SPUUpdater, didFinishUpdateCycleFor updateCheck: SPUUpdateCheck, error: Error?) {
        if let error {
            AppLogger.error("Sparkle: update cycle finished with error — \(error.localizedDescription)")
            CrashReportingManager.shared.record(error: error)
        } else {
            AppLogger.info("Sparkle: update cycle finished without error")
            CrashReportingManager.shared.log("sparkle: update cycle finished OK")
        }
        AnalyticsManager.shared.log(.updateCheckCompleted(succeeded: error == nil))
    }

    func updaterDidNotFindUpdate(_ updater: SPUUpdater) {
        AppLogger.info("Sparkle: no update found (or none offered)")
        CrashReportingManager.shared.log("sparkle: no update found")
    }

    func updater(_ updater: SPUUpdater, didFindValidUpdate item: SUAppcastItem) {
        AppLogger.info("Sparkle: valid update found — \(item.displayVersionString)")
        CrashReportingManager.shared.log("sparkle: update found - \(item.displayVersionString)")
        AnalyticsManager.shared.log(.updateFound(version: item.displayVersionString))
    }
    
    func updater(_ updater: SPUUpdater, failedToDownloadUpdate item: SUAppcastItem, error: Error) {
        AppLogger.error(
            "Sparkle: failed to download update \(item.displayVersionString) — \(error.localizedDescription)"
        )
        CrashReportingManager.shared.record(error: error)
    }
    
    func updater(_ updater: SPUUpdater, failedToApplyUpdate item: SUAppcastItem, error: Error) {
        AppLogger.error(
            "Sparkle: failed to apply update \(item.displayVersionString) — \(error.localizedDescription)"
        )
        CrashReportingManager.shared.record(error: error)
    }
    
    func updater(_ updater: SPUUpdater, didFinishLoading appcast: SUAppcast) {
        AppLogger.debug("Sparkle: finished loading appcast")
        CrashReportingManager.shared.log("sparkle: appcast loaded")
    }
    
    func updater(_ updater: SPUUpdater, willDownloadUpdate item: SUAppcastItem, with request: NSMutableURLRequest) {
        AppLogger.debug("Sparkle: will download update \(item.displayVersionString)")
        CrashReportingManager.shared.log("sparkle: download started - \(item.displayVersionString)")
    }
}
