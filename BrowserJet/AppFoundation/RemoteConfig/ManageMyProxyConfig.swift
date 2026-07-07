//
//  ManageMyProxyConfig.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 07/07/2026.
//

struct ManageMyProxyConfig: Decodable {
    static let supportedSchemaVersion = 1
    
    let schemaVersion: Int
    let linearRotationEnabled: Bool
    let randomRotationEnabled: Bool
    let maxGroupsPerAccount: Int
    let maxProxiesPerGroup: Int
    
    var isSupported: Bool {
        schemaVersion <= Self.supportedSchemaVersion
    }
    
    init(
        schemaVersion: Int = 1,
        linearRotationEnabled: Bool = true,
        randomRotationEnabled: Bool = true,
        maxGroupsPerAccount: Int = 20,
        maxProxiesPerGroup: Int = 500
    ) {
        self.schemaVersion = schemaVersion
        self.linearRotationEnabled = linearRotationEnabled
        self.randomRotationEnabled = randomRotationEnabled
        self.maxGroupsPerAccount = maxGroupsPerAccount
        self.maxProxiesPerGroup = maxProxiesPerGroup
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 1
        linearRotationEnabled = try container.decodeIfPresent(Bool.self, forKey: .linearRotationEnabled) ?? true
        randomRotationEnabled = try container.decodeIfPresent(Bool.self, forKey: .randomRotationEnabled) ?? true
        maxGroupsPerAccount = try container.decodeIfPresent(Int.self, forKey: .maxGroupsPerAccount) ?? 20
        maxProxiesPerGroup = try container.decodeIfPresent(Int.self, forKey: .maxProxiesPerGroup) ?? 500
    }
    
    private enum CodingKeys: String, CodingKey {
        case schemaVersion
        case linearRotationEnabled
        case randomRotationEnabled
        case maxGroupsPerAccount
        case maxProxiesPerGroup
    }
}

extension ManageMyProxyConfig {
    static let defaultJSONString = """
    {
      "schemaVersion": 1,
      "linearRotationEnabled": true,
      "randomRotationEnabled": true,
      "maxGroupsPerAccount": 20,
      "maxProxiesPerGroup": 500
    }
    """
    
    static let `default` = ManageMyProxyConfig(
        schemaVersion: 1,
        linearRotationEnabled: true,
        randomRotationEnabled: true,
        maxGroupsPerAccount: 20,
        maxProxiesPerGroup: 500
    )
}
