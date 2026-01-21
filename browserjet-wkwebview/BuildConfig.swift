//
//  BuildConfig.swift
//  browserjet-wkwebview
//
//  Created by Moiz Ul Hasan on 21/01/2026.
//

import Foundation

enum AppEnvironment: String, CaseIterable {
    case development = "DEVELOPMENT"
    case staging     = "STAGING"
    case production  = "PRODUCTION"

    /// Reads from Info.plist key: `APP_ENVIRONMENT`
    static var current: AppEnvironment = {
        let raw = Bundle.main.object(forInfoDictionaryKey: "APP_ENVIRONMENT") as? String
        let trimmed = raw?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if let env = AppEnvironment(rawValue: trimmed.uppercased()) {
            return env
        }

        #if DEBUG
        assertionFailure("""
        ❌ APP_ENVIRONMENT is missing/invalid.
        Found: '\(raw ?? "nil")'
        Expected one of: \(AppEnvironment.allCases.map(\.rawValue).joined(separator: ", "))
        Fix: Add APP_ENVIRONMENT = <value> in the correct .xcconfig and ensure Info.plist has APP_ENVIRONMENT = $(APP_ENVIRONMENT)
        """)
        #endif

        // Safe fallback for release builds
        return .production
    }()
}

// Optional convenience helpers (useful later for logging + feature flags)
extension AppEnvironment {
    var isProduction: Bool { self == .production }
    var isNonProduction: Bool { self != .production }

    /// Short display for UI badges, logs, etc.
    var displayName: String {
        switch self {
        case .development: return "Dev"
        case .staging:     return "Staging"
        case .production:  return "Prod"
        }
    }
}


enum BuildConfig {

    // MARK: - Generic accessor

    static func value<T>(for key: String) -> T {
        guard
            let value = Bundle.main.object(forInfoDictionaryKey: key) as? T
        else {
            fatalError("❌ Missing or invalid Info.plist key: \(key)")
        }
        return value
    }

    // MARK: - Environment

    static let environment: AppEnvironment = {
        let rawValue: String = value(for: "APP_ENVIRONMENT")

        guard let env = AppEnvironment(rawValue: rawValue) else {
            fatalError("❌ Invalid APP_ENVIRONMENT value: \(rawValue)")
        }

        return env
    }()

    // MARK: - Common build values

    static let productName: String = value(for: "CFBundleName")
    static let bundleIdentifier: String = value(for: "CFBundleIdentifier")
    static let marketingVersion: String = value(for: "CFBundleShortVersionString")
    static let buildNumber: String = value(for: "CFBundleVersion")

    static let swiftVersion: String = value(for: "SWIFT_VERSION")
    static let macOSDeploymentTarget: String = value(for: "MACOSX_DEPLOYMENT_TARGET")
    static let hardenedRuntimeEnabled: Bool = {
        let value_: String = value(for: "ENABLE_HARDENED_RUNTIME")
        return value_ == "YES"
    }()
}
