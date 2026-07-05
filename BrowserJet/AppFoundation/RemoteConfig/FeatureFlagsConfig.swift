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

    var isSupported: Bool {
        schemaVersion <= Self.supportedSchemaVersion
    }

    init(
        schemaVersion: Int = 1,
        shortcutsEnabled: Bool,
        crashReportingEnabled: Bool = true
    ) {
        self.schemaVersion = schemaVersion
        self.shortcutsEnabled = shortcutsEnabled
        self.crashReportingEnabled = crashReportingEnabled
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 1
        shortcutsEnabled = try container.decodeIfPresent(Bool.self, forKey: .shortcutsEnabled) ?? true
        crashReportingEnabled = try container.decodeIfPresent(Bool.self, forKey: .crashReportingEnabled) ?? true
    }

    private enum CodingKeys: String, CodingKey {
        case schemaVersion
        case shortcutsEnabled
        case crashReportingEnabled
    }
}

extension FeatureFlagsConfig {
    static let defaultJSONString = """
    {
      "schemaVersion": 1,
      "shortcutsEnabled": true,
      "crashReportingEnabled": true
    }
    """

    /// In-memory fallback when Firebase is unreachable or decode fails.
    static let `default` = FeatureFlagsConfig(
        schemaVersion: 1,
        shortcutsEnabled: true,
        crashReportingEnabled: true
    )
}
