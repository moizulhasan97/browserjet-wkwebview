//
//  SparkleUpdateCoordinator.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 28/04/2026.
//

import AppKit
import Sparkle

enum SparklePolicyApplicationContext: Sendable {
    /// After Firebase Remote Config fetch; handles **forced** below-minimum path only.
    case afterRemoteConfigFetch
    /// Launcher visible; handles **optional** update at most once per app session.
    case launcherAppeared
}

@MainActor
final class SparkleUpdateCoordinator {
    
    static let shared = SparkleUpdateCoordinator()
    
    private weak var updaterController: SPUStandardUpdaterController?
    private var didTriggerOptionalCheckThisSession = false
    
    private init() {}
    
    func register(_ controller: SPUStandardUpdaterController) {
        updaterController = controller
    }
    
    func applyPolicyResult(_ result: AppUpdatePolicyResult, context: SparklePolicyApplicationContext) {
        guard let controller = updaterController else {
            AppLogger.warning("SparkleUpdateCoordinator: updater not registered — skipping checkForUpdates")
            return
        }
        
        switch context {
        case .afterRemoteConfigFetch:
            switch result {
            case .belowMinimum:
                activateForceUpdateGate(
                    requiredMarketingKey: .macOSAppMinimumSupportedMarketingVersion,
                    requiredBuildKey: .macOSAppMinimumSupportedBuildVersion,
                    logLabel: "below minimum — always required"
                )
            case .forcedBelowLatest:
                activateForceUpdateGate(
                    requiredMarketingKey: .macOSAppLatestMarketingVersion,
                    requiredBuildKey: .macOSAppLatestBuildVersion,
                    logLabel: "below latest with force_update_enabled"
                )
            case .optionalUpdateAvailable, .upToDate:
                break
            }
            
        case .launcherAppeared:
            guard case .optionalUpdateAvailable = result else { return }
            guard !didTriggerOptionalCheckThisSession else { return }
            didTriggerOptionalCheckThisSession = true
            AppLogger.info("SparkleUpdateCoordinator: optional update — single checkForUpdates this session (Sparkle handles Later/Skip)")
            controller.checkForUpdates(nil)
        }
    }
    
    private func activateForceUpdateGate(
        requiredMarketingKey: RemoteConfigKey,
        requiredBuildKey: RemoteConfigKey,
        logLabel: String
    ) {
        let marketing = AppUtils.getAppMarketingVersion()
        let build = AppUtils.getAppBuildVersion()
        let remote = RemoteConfigManager.shared
        let reqMarketing = remote.string(for: requiredMarketingKey)
        let reqBuild = remote.number(for: requiredBuildKey).intValue
        AppLogger.info("SparkleUpdateCoordinator: \(logLabel) — activating forced update gate")
        ForceUpdateGate.shared.activateRequiredUpdate(
            currentMarketing: marketing,
            currentBuild: build,
            requiredMarketing: reqMarketing,
            requiredBuild: reqBuild,
            manualDownloadURL: remote.resolvedManualDownloadURL
        )
    }
}
