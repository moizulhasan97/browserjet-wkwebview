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
    private let cachedPremiumProxiesKey = "CachedPremiumProxies"
    @Published private(set) var proxies: [DecryptedPremiumProxy] = []
    @Published private(set) var isLoading: Bool = false

    var hasPremiumProxies: Bool { !proxies.isEmpty }

    init(proxyService: ProxyService = ProxyService(), keyValueStore: KeyValueStoring = UserDefaultsKeyValueStore()) {
        self.proxyService = proxyService
        self.keyValueStore = keyValueStore
        keyValueStore.removeObject(forKey: cachedPremiumProxiesKey)
        //loadFromCache()
    }

    /// Same as CEF `PremiumProvider` / `preloadRemoteProxies` success path: restore last decoded list for offline / failed refresh.
//    private func loadFromCache() {
//        guard let data = keyValueStore.object(forKey: StorageKeys.encryptedPremiumProxies) as? Data else {
//            return
//        }
//        if let rows = try? JSONDecoder().decode([DecryptedPremiumProxy].self, from: data), !rows.isEmpty {
//            proxies = rows
//            AppLogger.info("PremiumProxyRepository: loaded \(proxies.count) cached premium proxy row(s)")
//            return
//        }
//        if let wrapped = try? JSONDecoder().decode(DecryptedPremiumProxies.self, from: data), !wrapped.premiumProxies.isEmpty {
//            proxies = wrapped.premiumProxies
//            AppLogger.info("PremiumProxyRepository: loaded \(proxies.count) cached premium proxy row(s) (wrapped)")
//        }
//    }

    private func saveToCache(_ rows: [DecryptedPremiumProxy]) {
        guard !rows.isEmpty else { return }
        do {
            let encoded = try JSONEncoder().encode(rows)
            keyValueStore.set(encoded, forKey: StorageKeys.encryptedPremiumProxies)
        } catch {
            AppLogger.warning("PremiumProxyRepository: encode cache failed — \(error.localizedDescription)")
        }
    }

    /// CEF: remove decrypted list when fetch fails or key changes.
    private func removeCache() {
        keyValueStore.removeObject(forKey: StorageKeys.encryptedPremiumProxies)
    }

    /// Call when the license key changes so we never reuse another user’s list (CEF clears UserDefaults on failure / key change).
    func clearForLicenseChange() {
        proxies = []
        removeCache()
        AppLogger.info("PremiumProxyRepository: cleared premium proxies (license change)")
    }

    /// Fetches GPP when the launcher appears; on success persists like CEF; on failure clears cache and memory.
    func refreshFromNetworkIfPossible() async {
        guard
            let key = keyValueStore.object(forKey: StorageKeys.licenseKey) as? String,
            !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            proxies = []
            removeCache()
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
            saveToCache(rows)
            AppLogger.info("PremiumProxyRepository: fetched \(proxies.count) premium proxy row(s)")
        } catch {
            proxies = []
            removeCache()
            AppLogger.warning("PremiumProxyRepository: fetch failed (silent) — \(error.localizedDescription)")
        }
    }

    func authProxiesForSession() -> [AuthProxy] {
        proxies.map { $0.asAuthProxy() }
    }
}
