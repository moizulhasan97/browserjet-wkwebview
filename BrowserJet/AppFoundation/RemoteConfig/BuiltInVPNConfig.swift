//
//  BuiltInVPNConfig.swift
//  BrowserJet
//

import Foundation

/// Remote Config `builtin_vpn_config`: proxy pool definitions for built-in VPN tiers, keyed by `VPNType.rawValue`.
/// Carries credentials, so the raw value is never logged (see `RemoteConfigKey.isSensitive`).
struct BuiltInVPNConfig: Decodable {
    static let supportedSchemaVersion = 1

    let schemaVersion: Int
    let pools: [String: ProxyPoolTemplate]

    var isSupported: Bool {
        schemaVersion <= Self.supportedSchemaVersion
    }

    init(schemaVersion: Int = 1, pools: [String: ProxyPoolTemplate]) {
        self.schemaVersion = schemaVersion
        self.pools = pools
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 1
        pools = try container.decodeIfPresent([String: ProxyPoolTemplate].self, forKey: .pools) ?? [:]
    }

    private enum CodingKeys: String, CodingKey {
        case schemaVersion, pools
    }
}

extension BuiltInVPNConfig {
    /// In-app default has no pools: credentials are never bundled, so built-in VPN stays
    /// unavailable until Remote Config delivers (and Firebase caches) the real value.
    static let defaultJSONString = """
    {
      "schemaVersion": 1,
      "pools": {}
    }
    """

    static let `default` = BuiltInVPNConfig(schemaVersion: 1, pools: [:])
}
