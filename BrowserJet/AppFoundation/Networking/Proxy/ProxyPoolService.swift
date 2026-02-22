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

protocol AuthProxyProvider {
    func loadPool() -> [AuthProxy]
}

final class ProxyPoolService {

    private var provider: AuthProxyProvider?
    private var pool: [AuthProxy] = []
    private var rotation: ProxyRotationType = .linear

    /// Assigned proxy per session slot
    private var assigned: [AuthProxy?] = []

    private var linearIndex: Int = 0

    private var randomDeck: [AuthProxy] = []
    private var randomCursor: Int = 0

    func configure(
        provider: AuthProxyProvider,
        rotation: ProxyRotationType
    ) {
        self.provider = provider
        self.rotation = rotation
        reloadPool()
    }

    private func reloadPool() {
        pool = provider?.loadPool() ?? []
        assigned.removeAll()
        linearIndex = 0
        randomDeck.removeAll()
        randomCursor = 0
    }

    func getProxy(for slot: Int) -> AuthProxy? {
        guard !pool.isEmpty else { return nil }

        if slot < assigned.count, let existing = assigned[slot] {
            return existing
        }

        guard let next = nextProxyFromRotation() else { return nil }
        ensureAssignedCapacity(upTo: slot)
        assigned[slot] = next
        return next
    }

    func burnProxy(for slot: Int) -> AuthProxy? {
        guard !pool.isEmpty else { return nil }
        guard let replacement = nextProxyFromRotation() else { return nil }

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
            assigned.append(contentsOf: Array<AuthProxy?>(repeating: nil, count: slot - assigned.count + 1))
        }
    }

    private func nextProxyFromRotation() -> AuthProxy? {
        switch rotation {
        case .linear:
            let proxy = pool[linearIndex % pool.count]
            linearIndex += 1
            return proxy

        case .random:
            if randomDeck.isEmpty || randomCursor >= randomDeck.count {
                randomDeck = pool.shuffled()
                randomCursor = 0
            }
            let proxy = randomDeck[randomCursor]
            randomCursor += 1
            return proxy
        }
    }
}
