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

    func getPremiumProxies(key: String, email: String) async throws -> Data {
        try await client.requestData(ProxyEndpoint.premium(key: key, email: email))
    }

    func getVPN1Proxies(key: String) async throws -> Data {
        try await client.requestData(ProxyEndpoint.vpn1(key: key))
    }
}
