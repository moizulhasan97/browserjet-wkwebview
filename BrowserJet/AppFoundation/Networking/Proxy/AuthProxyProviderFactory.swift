//
//  AuthProxyProviderFactory.swift
//  BrowserJet
//

import Foundation

/// Resolves the proxy provider for a browser launch from its `ProxyType`.
/// Keeps per-tier branching out of `WindowManager`; new proxy tiers plug in here.
@MainActor
struct AuthProxyProviderFactory {
    private let vpnProvider: VPNProvider
    private let premiumProxies: @MainActor () -> [AuthProxy]

    init(vpnProvider: VPNProvider, premiumProxies: @escaping @MainActor () -> [AuthProxy]) {
        self.vpnProvider = vpnProvider
        self.premiumProxies = premiumProxies
    }

    /// `nil` for local sessions, and for proxied sessions that have nothing to route through.
    func makeProvider(for proxyType: ProxyType) -> AuthProxyProviding? {
        guard case .proxy(let source) = proxyType else { return nil }

        switch source {
        case .premium:
            let proxies = premiumProxies()
            return proxies.isEmpty ? nil : ListAuthProxyProvider(proxies: proxies)

        case let .builtIn(vpn, region):
            return vpnProvider.makeProxyProvider(for: vpn, region: region)

        case .custom:
            return nil
        }
    }
}
