//
//  FeatureFlagsConfig.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 05/07/2026.
//

import Foundation

struct FeatureFlagsConfig: Decodable {
    static let supportedSchemaVersion = 1

    let schemaVersion: Int
    let shortcutsEnabled: Bool
    let crashReportingEnabled: Bool
    let analyticsEnabled: Bool

    var isSupported: Bool {
        schemaVersion <= Self.supportedSchemaVersion
    }

    /// Comma-separated summary of active flags, attached as a custom key/property to both
    /// Crashlytics and Analytics so a report can be cross-referenced against what was live.
    var activeFeatureFlagsSummary: String {
        var active: [String] = []
        if shortcutsEnabled { active.append("shortcuts") }
        if crashReportingEnabled { active.append("crash_reporting") }
        if analyticsEnabled { active.append("analytics") }
        return active.isEmpty ? "none" : active.joined(separator: ",")
    }

    init(
        schemaVersion: Int = 1,
        shortcutsEnabled: Bool,
        crashReportingEnabled: Bool = true,
        analyticsEnabled: Bool = true
    ) {
        self.schemaVersion = schemaVersion
        self.shortcutsEnabled = shortcutsEnabled
        self.crashReportingEnabled = crashReportingEnabled
        self.analyticsEnabled = analyticsEnabled
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 1
        shortcutsEnabled = try container.decodeIfPresent(Bool.self, forKey: .shortcutsEnabled) ?? true
        crashReportingEnabled = try container.decodeIfPresent(Bool.self, forKey: .crashReportingEnabled) ?? true
        analyticsEnabled = try container.decodeIfPresent(Bool.self, forKey: .analyticsEnabled) ?? true
    }

    private enum CodingKeys: String, CodingKey {
        case schemaVersion
        case shortcutsEnabled
        case crashReportingEnabled
        case analyticsEnabled
    }
}

extension FeatureFlagsConfig {
    static let defaultJSONString = """
    {
      "schemaVersion": 1,
      "shortcutsEnabled": true,
      "crashReportingEnabled": true,
      "analyticsEnabled": true
    }
    """

    /// In-memory fallback when Firebase is unreachable or decode fails.
    static let `default` = FeatureFlagsConfig(
        schemaVersion: 1,
        shortcutsEnabled: true,
        crashReportingEnabled: true,
        analyticsEnabled: true
    )
}
