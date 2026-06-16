//
//  ProxyService.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 24/02/2026.
//

import Foundation

final class ProxyService {
    private let client: APIClient

    init(client: APIClient = .shared) {
        self.client = client
    }

    func getPremiumProxies(key: String) async throws -> Data {
        AppLogger.info("ProxyService: fetching premium proxies (GPP)")
        do {
            let data = try await client.requestData(ProxyEndpoint.premium(key: key))
            AppLogger.info("ProxyService: received premium proxies - \(data.count) bytes")
            return data
        } catch {
            AppLogger.error("ProxyService: getPremiumProxies failed - \(error.localizedDescription)")
            throw error
        }
    }

    func getVPN1Proxies(key: String) async throws -> Data {
        AppLogger.info("ProxyService: fetching VPN1 proxies (VPR)")
        do {
            let data = try await client.requestData(ProxyEndpoint.vpn1(key: key))
            AppLogger.info("ProxyService: received VPN1 proxies - \(data.count) bytes")
            return data
        } catch {
            AppLogger.error("ProxyService: getVPN1Proxies failed - \(error.localizedDescription)")
            throw error
        }
    }
}
