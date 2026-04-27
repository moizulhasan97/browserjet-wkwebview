//
//  AppUpdatePolicy.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 27/04/2026.
//

import Foundation

enum AppUpdatePolicyResult: Equatable {
    case upToDate
    case belowMinimum(forceUpdateEnabled: Bool)
    case optionalUpdateAvailable
}

enum AppUpdatePolicy {

    @MainActor
    static func evaluateBuild(remote: RemoteConfigManager = .shared) -> AppUpdatePolicyResult {
        let forceEnabled = remote.bool(for: .forceUpdateEnabled)
        let optionalEnabled = remote.bool(for: .optionalUpdateEnabled)

        let minMarketing = remote.string(for: .macOSAppMinimumSupportedMarketingVersion)
        let minBuild = remote.number(for: .macOSAppMinimumSupportedBuildVersion).intValue
        let latestMarketing = remote.string(for: .macOSAppLatestMarketingVersion)
        let latestBuild = remote.number(for: .macOSAppLatestBuildVersion).intValue

        let currentMarketing = AppUtils.getAppMarketingVersion()
        let currentBuild = AppUtils.getAppBuildVersion()

        AppLogger.info("[AppUpdatePolicy] local marketing=\(currentMarketing) build=\(currentBuild)")
        AppLogger.info("[AppUpdatePolicy] RC minimum marketing=\(minMarketing) build=\(minBuild)")
        AppLogger.info("[AppUpdatePolicy] RC latest marketing=\(latestMarketing) build=\(latestBuild)")
        AppLogger.info("[AppUpdatePolicy] RC force_update_enabled=\(forceEnabled) optional_update_enabled=\(optionalEnabled)")
        
        let belowMinimum = isVersionLessThan(
            marketing: currentMarketing, build: currentBuild,
            thanMarketing: minMarketing, thanBuild: minBuild
        )
        let belowLatest = isVersionLessThan(
            marketing: currentMarketing, build: currentBuild,
            thanMarketing: latestMarketing, thanBuild: latestBuild
        )

        AppLogger.info("[AppUpdatePolicy] belowMinimum=\(belowMinimum) belowLatest=\(belowLatest)")

        if belowMinimum {
            AppLogger.warning("[AppUpdatePolicy] branch: below minimum supported (force flag=\(forceEnabled))")
            if forceEnabled {
                print("[Sparkle] TODO: blocking / required-update UX — hold rest of app until resolved")
                print("[Sparkle] TODO: e.g. SPUStandardUpdaterController.checkForUpdates(_:) or feed-only critical path")
                print("[Sparkle] TODO: consider critical update / minimumVersion in appcast aligned with RC minimum")
            } else {
                print("[Sparkle] TODO: below minimum but force_update_enabled=false — product may still call checkForUpdates or stay silent")
            }
            return .belowMinimum(forceUpdateEnabled: forceEnabled)
        }

        if belowLatest {
            if optionalEnabled {
                AppLogger.warning("[AppUpdatePolicy] branch: optional update available (Sparkle handles remind/skip)")
                print("[Sparkle] TODO: optional update — trigger user-initiated or scheduled check, e.g. checkForUpdates(_:)")
                print("[Sparkle] TODO: do not add custom Later/skip timers here; rely on Sparkle standard UI")
                return .optionalUpdateAvailable
            } else {
                AppLogger.warning("[AppUpdatePolicy] branch: below latest but optional_update_enabled=false — no nag")
                print("[Sparkle] TODO: none — optional nag disabled by Remote Config")
                return .upToDate
            }
        }

        AppLogger.info("[AppUpdatePolicy] branch: up to date")
        print("[Sparkle] TODO: none — app meets or exceeds RC latest")
        return .upToDate
    }

    /// True if (currentMarketing, currentBuild) is older than (thanMarketing, thanBuild).
    private static func isVersionLessThan(
        marketing: String, build: Int,
        thanMarketing: String, thanBuild: Int
    ) -> Bool {
        switch compareSemver(marketing, thanMarketing) {
        case .orderedAscending:
            return true
        case .orderedDescending:
            return false
        case .orderedSame:
            return build < thanBuild
        }
    }

    private static func compareSemver(_ a: String, _ b: String) -> ComparisonResult {
        let parsedSemanticVersionA = parseSemver(a)
        let parsedSemanticVersionB = parseSemver(b)
        if parsedSemanticVersionA.major != parsedSemanticVersionB.major { return parsedSemanticVersionA.major < parsedSemanticVersionB.major ? .orderedAscending : .orderedDescending }
        if parsedSemanticVersionA.minor != parsedSemanticVersionB.minor { return parsedSemanticVersionA.minor < parsedSemanticVersionB.minor ? .orderedAscending : .orderedDescending }
        if parsedSemanticVersionA.patch != parsedSemanticVersionB.patch { return parsedSemanticVersionA.patch < parsedSemanticVersionB.patch ? .orderedAscending : .orderedDescending }
        return .orderedSame
    }

    private static func parseSemver(_ s: String) -> (major: Int, minor: Int, patch: Int) {
        let parts = s.split(separator: ".").map(String.init)
        let major = Int(parts[safe: 0] ?? "") ?? 0
        let minor = Int(parts[safe: 1] ?? "") ?? 0
        let patch = Int(parts[safe: 2] ?? "") ?? 0
        return (major, minor, patch)
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard index >= 0, index < count else { return nil }
        return self[index]
    }
}
