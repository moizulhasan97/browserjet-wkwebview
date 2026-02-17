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
