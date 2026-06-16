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

/// Aggregates a marketing version string and build number into a single comparable value.
struct VersionTuple: Equatable {
    let marketing: String
    let build: Int
}

enum AppUpdatePolicy {
    @MainActor
    static func evaluateBuild(remote: RemoteConfigManager = .shared) -> AppUpdatePolicyResult {
        let forceEnabled = remote.bool(for: .forceUpdateEnabled)
        let optionalEnabled = remote.bool(for: .optionalUpdateEnabled)

        let minimum = VersionTuple(
            marketing: remote.string(for: .macOSAppMinimumSupportedMarketingVersion),
            build: remote.number(for: .macOSAppMinimumSupportedBuildVersion).intValue
        )
        let latest = VersionTuple(
            marketing: remote.string(for: .macOSAppLatestMarketingVersion),
            build: remote.number(for: .macOSAppLatestBuildVersion).intValue
        )
        let current = VersionTuple(
            marketing: AppUtils.getAppMarketingVersion(),
            build: AppUtils.getAppBuildVersion()
        )

        AppLogger.info("[AppUpdatePolicy] local marketing=\(current.marketing) build=\(current.build)")
        AppLogger.info("[AppUpdatePolicy] RC minimum marketing=\(minimum.marketing) build=\(minimum.build)")
        AppLogger.info("[AppUpdatePolicy] RC latest marketing=\(latest.marketing) build=\(latest.build)")
        AppLogger.info(
            """
            [AppUpdatePolicy] RC force_update_enabled=\(forceEnabled) \
            optional_update_enabled=\(optionalEnabled)
            """
        )

        let belowMinimum = isVersionLessThan(current, than: minimum)
        let belowLatest = isVersionLessThan(current, than: latest)

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

    /// True if `current` is older than `other`.
    private static func isVersionLessThan(_ current: VersionTuple, than other: VersionTuple) -> Bool {
        switch compareSemver(current.marketing, other.marketing) {
        case .orderedAscending:
            return true
        case .orderedDescending:
            return false
        case .orderedSame:
            return current.build < other.build
        }
    }

    private static func compareSemver(_ lhs: String, _ rhs: String) -> ComparisonResult {
        let lhsVersion = parseSemver(lhs)
        let rhsVersion = parseSemver(rhs)
        if lhsVersion.major != rhsVersion.major {
            return lhsVersion.major < rhsVersion.major ? .orderedAscending : .orderedDescending
        }
        if lhsVersion.minor != rhsVersion.minor {
            return lhsVersion.minor < rhsVersion.minor ? .orderedAscending : .orderedDescending
        }
        if lhsVersion.patch != rhsVersion.patch {
            return lhsVersion.patch < rhsVersion.patch ? .orderedAscending : .orderedDescending
        }
        return .orderedSame
    }

    private struct SemanticVersion {
        let major: Int
        let minor: Int
        let patch: Int
    }

    private static func parseSemver(_ version: String) -> SemanticVersion {
        let parts = version.split(separator: ".").map(String.init)
        return SemanticVersion(
            major: Int(parts[safe: 0] ?? "") ?? 0,
            minor: Int(parts[safe: 1] ?? "") ?? 0,
            patch: Int(parts[safe: 2] ?? "") ?? 0
        )
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard index >= 0, index < count else { return nil }
        return self[index]
    }
}
