//
//  PremiumProxyRepository.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 27/03/2026.
//

import Foundation

@MainActor
final class PremiumProxyRepository: ObservableObject {
    static let shared = PremiumProxyRepository()

    private let proxyService: ProxyService
    private let keyValueStore: KeyValueStoring

    @Published private(set) var proxies: [DecryptedPremiumProxy] = []
    @Published private(set) var isLoading: Bool = false

    var hasPremiumProxies: Bool { !proxies.isEmpty }

    init(proxyService: ProxyService = ProxyService(), keyValueStore: KeyValueStoring = UserDefaultsKeyValueStore()) {
        self.proxyService = proxyService
        self.keyValueStore = keyValueStore
    }

    func clearForLicenseChange() {
        proxies = []
        AppLogger.info("PremiumProxyRepository: cleared in-memory premium proxies (license change)")
    }

    func refreshFromNetworkIfPossible() async {
        guard
            let key = keyValueStore.object(forKey: StorageKeys.licenseKey) as? String,
            !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            proxies = []
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let data = try await proxyService.getPremiumProxies(key: key)
            let rows = try PremiumProxyPayloadDecryptor.decodePremiumProxies(from: data)
            guard !rows.isEmpty else {
                throw PremiumProxyDecryptError.emptyProxyList
            }
            proxies = rows
            AppLogger.info("PremiumProxyRepository: fetched \(proxies.count) premium proxy row(s)")
        } catch {
            proxies = []
            AppLogger.warning("PremiumProxyRepository: fetch failed (silent) — \(error.localizedDescription)")
        }
    }

    func authProxiesForSession() -> [AuthProxy] {
        proxies.map { $0.asAuthProxy() }
    }
}
