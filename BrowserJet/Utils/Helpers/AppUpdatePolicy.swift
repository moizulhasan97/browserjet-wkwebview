//
//  AppUpdatePolicy.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 27/04/2026.
//

import Foundation

enum AppUpdatePolicyResult: Equatable {
    case upToDate
    
    /// Below Remote Config minimum — always required (ignores `force_update_enabled`).
    case belowMinimum
    
    /// At/above minimum but below latest while `force_update_enabled` — blocking required update.
    case forcedBelowLatest
    
    /// At/above minimum but below latest while `force_update_enabled` is false — optional Sparkle flow.
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
            return .belowMinimum
        }
        
        if belowLatest {
            if forceEnabled {
                return .forcedBelowLatest
            }
            if optionalEnabled {
                return .optionalUpdateAvailable
            }
            return .upToDate
        }
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
