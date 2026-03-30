//
//  DecryptedPremiumProxy.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 27/03/2026.
//

import Foundation

struct DecryptedPremiumProxy: Codable, Hashable {
    let ipID: Int
    let ip: String
    let port: Int
    let username: String
    let password: String
    let createdOn: String

    enum CodingKeys: String, CodingKey {
        case ipID = "IP_ID"
        case ip = "IP"
        case port
        case username
        case password
        case createdOn = "CreatedOn"
    }
}

struct DecryptedPremiumProxies: Codable {
    let premiumProxies: [DecryptedPremiumProxy]

    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        var rows: [DecryptedPremiumProxy] = []
        while !container.isAtEnd {
            rows.append(try container.decode(DecryptedPremiumProxy.self))
        }
        self.premiumProxies = rows
    }
}

extension DecryptedPremiumProxy {
    /// Maps API row into WebKit proxy credentials.
    func asAuthProxy() -> AuthProxy {
        AuthProxy(
            host: ip,
            port: UInt16(clamping: port),
            username: username,
            password: password
        )
    }
}
