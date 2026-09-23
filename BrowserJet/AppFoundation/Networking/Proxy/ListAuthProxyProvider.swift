//
//  ListAuthProxyProvider.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 22/02/2026.
//

import Foundation

/// Hands out proxies from a fixed list (e.g. Premium rows) with linear or shuffled rotation.
/// Proxies repeat once the list is exhausted.
final class ListAuthProxyProvider: AuthProxyProviding {
    private let proxies: [AuthProxy]
    private let rotation: ProxyRotationType

    private var linearIndex: Int = 0
    private var randomDeck: [AuthProxy] = []
    private var randomCursor: Int = 0

    init(proxies: [AuthProxy], rotation: ProxyRotationType = .linear) {
        self.proxies = proxies
        self.rotation = rotation
    }

    func nextProxy() -> AuthProxy? {
        guard !proxies.isEmpty else { return nil }

        switch rotation {
        case .linear:
            let proxy = proxies[linearIndex % proxies.count]
            linearIndex += 1
            return proxy

        case .random:
            if randomCursor >= randomDeck.count {
                randomDeck = proxies.shuffled()
                randomCursor = 0
            }
            let proxy = randomDeck[randomCursor]
            randomCursor += 1
            return proxy
        }
    }
}
