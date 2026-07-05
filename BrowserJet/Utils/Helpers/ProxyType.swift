//
//  ProxyType.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 13/02/2026.
//

import Foundation

enum ProxyType: Hashable {
    case local
    case proxy(ProxySource)
}

enum ProxySource: Hashable {
    case builtIn(vpn: VPNType, region: RegionType)
    case premium(vpn: VPNType, region: RegionType)
    case custom
}

extension ProxyType {
    var isLocal: Bool {
        if case .local = self { return true }
        return false
    }

    /// True when launcher resolved to premium (GPP) pool instead of built-in `VPNProvider` configs.
    var isPremiumSession: Bool {
        guard case .proxy(let source) = self else { return false }
        if case .premium = source { return true }
        return false
    }

    /// Built-in VPN tier when `proxy` is `.builtIn`; otherwise `nil`.
    var builtInVPNType: VPNType? {
        guard case .proxy(.builtIn(let vpn, _)) = self else { return nil }
        return vpn
    }

    /// For browser window UI.
    var statusTitle: String {
        switch self {
        case .local: return "Local"
        case .proxy(let source):
            switch source {
            case .builtIn: return "On VPN"
            case .premium: return "Premium"
            case .custom:  return "Custom"
            }
        }
    }
    
    /// Diagnostic-only identifier for crash reporting — more specific than `statusTitle`.
    var diagnosticIdentifier: String {
        switch self {
        case .local:
            return "Local"
        case .proxy(let source):
            switch source {
            case .builtIn(let vpn, let region):
                return "\(vpn.rawValue.uppercased()) (\(region.rawValue))"
            case .premium(let vpn, let region):
                return "Premium \(vpn.rawValue.uppercased()) (\(region.rawValue))"
            case .custom:
                return "Custom"
            }
        }
    }

    /// Temporary resolver (until API + storage exists).
    /// - For now: local => nil, proxy => pick proxies[slot] else first proxy.
    func resolveAuthProxy(slot: Int, proxies: [AuthProxy]) -> AuthProxy? {
        switch self {
        case .local:
            return nil
        case .proxy:
            if proxies.indices.contains(slot) { return proxies[slot] }
            return proxies.first
        }
    }
}
