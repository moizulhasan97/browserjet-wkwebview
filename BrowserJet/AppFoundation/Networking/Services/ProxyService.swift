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
}
