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
    
    // TODO: Firebase — log update_check lifecycle (start/end, success/error).
    
    func updater(_ updater: SPUUpdater, didFinishUpdateCycleFor updateCheck: SPUUpdateCheck, error: Error?) {
        if let error {
            AppLogger.error("Sparkle: update cycle finished with error — \(error.localizedDescription)")
            // TODO: Crashlytics.record(error:) and/or Analytics event `sparkle_update_cycle_error` (keys: domain, code, NSErrorBridgedDescription)
        } else {
            AppLogger.info("Sparkle: update cycle finished without error")
            // TODO: Analytics — `sparkle_update_cycle_success` (optional: include updateCheck if useful)
        }
    }
    
    func updaterDidNotFindUpdate(_ updater: SPUUpdater) {
        AppLogger.info("Sparkle: no update found (or none offered)")
        // TODO: Analytics — `sparkle_no_update_found`
    }
    
    func updater(_ updater: SPUUpdater, didFindValidUpdate item: SUAppcastItem) {
        AppLogger.info("Sparkle: valid update found — \(item.displayVersionString)")
        // TODO: Analytics — `sparkle_update_found` (params: displayVersionString, minimumSystemVersion, etc. — avoid PII)
    }
    
    // MARK: - Download / install failures
    func updater(_ updater: SPUUpdater, failedToDownloadUpdate item: SUAppcastItem, error: Error) {
        AppLogger.error("Sparkle: failed to download update \(item.displayVersionString) — \(error.localizedDescription)")
        // TODO: Crashlytics.record(error:) + Analytics `sparkle_download_failed`
    }
    
    func updater(_ updater: SPUUpdater, failedToApplyUpdate item: SUAppcastItem, error: Error) {
        AppLogger.error("Sparkle: failed to apply update \(item.displayVersionString) — \(error.localizedDescription)")
        // TODO: Crashlytics.record(error:) + Analytics `sparkle_apply_failed`
    }
    
    // MARK: - Appcast / network (optional — may not fire in all flows)
    
    func updater(_ updater: SPUUpdater, didFinishLoading appcast: SUAppcast) {
        AppLogger.debug("Sparkle: finished loading appcast")
        // TODO: Analytics — `sparkle_appcast_loaded` (debug-level; may be noisy)
    }
    
    func updater(_ updater: SPUUpdater, willDownloadUpdate item: SUAppcastItem, with request: NSMutableURLRequest) {
        AppLogger.debug("Sparkle: will download update \(item.displayVersionString)")
        // TODO: Analytics — `sparkle_download_started` (optional; can duplicate download_failed funnel)
    }
}
