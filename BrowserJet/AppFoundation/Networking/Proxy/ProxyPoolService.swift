//
//  ProxyPoolService.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 22/02/2026.
//

import Foundation

enum ProxyRotationType: Hashable {
    case linear
    case random
}

/// Produces proxies one at a time for `ProxyPoolService`. Each implementation owns its rotation and
/// uniqueness rules, so a browser window never needs a whole proxy list in memory.
protocol AuthProxyProviding: AnyObject {
    /// The next proxy to hand out, or `nil` when the source cannot produce one.
    func nextProxy() -> AuthProxy?
}

/// Per-window bookkeeping of which proxy is assigned to which session slot.
final class ProxyPoolService {
    private var provider: AuthProxyProviding?

    /// Assigned proxy per session slot
    private var assigned: [AuthProxy?] = []

    func configure(provider: AuthProxyProviding) {
        self.provider = provider
        assigned.removeAll()
    }

    func getProxy(for slot: Int) -> AuthProxy? {
        if slot < assigned.count, let existing = assigned[slot] {
            return existing
        }

        guard let next = provider?.nextProxy() else { return nil }
        ensureAssignedCapacity(upTo: slot)
        assigned[slot] = next
        return next
    }

    /// Replaces the slot's proxy with the provider's next one (for generated pools: a new session, so a new exit IP).
    func burnProxy(for slot: Int) -> AuthProxy? {
        guard let replacement = provider?.nextProxy() else { return nil }

        ensureAssignedCapacity(upTo: slot)
        assigned[slot] = replacement
        return replacement
    }

    func removeProxy(for slot: Int) {
        guard slot < assigned.count else { return }
        assigned[slot] = nil
    }

    private func ensureAssignedCapacity(upTo slot: Int) {
        if slot >= assigned.count {
            assigned.append(contentsOf: [AuthProxy?](repeating: nil, count: slot - assigned.count + 1))
        }
    }
}
