//
//  VPNType.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 12/02/2026.
//

enum VPNType: String, Hashable, CaseIterable {
    case vpn1
    case vpn2

    // Make it configurable
    static func from(configurations: [VPNConfiguration]) -> [VPNType] {
        return configurations.compactMap { config in
            VPNType(rawValue: config.id)
        }
    }

    static func displayName(for vpnType: VPNType, in configurations: [VPNConfiguration]) -> String {
        return configurations.first { $0.id == vpnType.rawValue }?.displayName ?? vpnType.rawValue
    }
}
