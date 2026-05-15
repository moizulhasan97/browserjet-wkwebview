//
//  VPN1ProxyRepository.swift
//  BrowserJet
//

import Foundation

@MainActor
final class VPN1ProxyRepository: ObservableObject {
    static let shared = VPN1ProxyRepository()

    private let proxyService: ProxyService
    private let keyValueStore: KeyValueStoring

    @Published private(set) var proxies: [DecryptedPremiumProxy] = []

    var hasVPN1Proxies: Bool { !proxies.isEmpty }

    init(proxyService: ProxyService = ProxyService(), keyValueStore: KeyValueStoring = UserDefaultsKeyValueStore()) {
        self.proxyService = proxyService
        self.keyValueStore = keyValueStore
    }

    func clearForLicenseChange() {
        proxies = []
        AppLogger.info("VPN1ProxyRepository: cleared in-memory VPN1 proxies (license change)")
    }

    func refreshFromNetworkIfPossible() async {
        guard
            let key = keyValueStore.object(forKey: StorageKeys.licenseKey) as? String,
            !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            proxies = []
            return
        }

        do {
            let data = try await proxyService.getVPN1Proxies(key: key)
            let rows = try PremiumProxyPayloadDecryptor.decodeVPN1Proxies(from: data)
            guard !rows.isEmpty else {
                throw PremiumProxyDecryptError.emptyProxyList
            }
            proxies = rows
            AppLogger.info("VPN1ProxyRepository: fetched \(proxies.count) VPN1 proxy row(s)")
        } catch {
            proxies = []
            AppLogger.info("VPN1ProxyRepository: VPN1 fetch unavailable — \(error.localizedDescription)")
        }
    }

    func authProxiesForSession() -> [AuthProxy] {
        proxies.map { $0.asAuthProxy() }
    }
}
