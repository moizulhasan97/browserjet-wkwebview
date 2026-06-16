//
//  DecryptedPremiumProxy.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 27/03/2026.
//

import Foundation

// MARK: - VPN1 API DTO (CEF `VPN1ProxyDTO`; `Port` is a string in JSON)

struct VPN1ProxyDTO: Codable {
    let vpnID: Int
    let ipAddress: String
    let port: String
    let username: String
    let password: String
    let createdOn: String

    enum CodingKeys: String, CodingKey {
        case vpnID = "VPN_ID"
        case ipAddress = "IP"
        case port = "Port"
        case username = "Username"
        case password = "Password"
        case createdOn = "CreatedOn"
    }

    func asDecryptedPremiumProxy() -> DecryptedPremiumProxy {
        DecryptedPremiumProxy(
            ipID: vpnID,
            ipAddress: ipAddress,
            port: Int(port) ?? 0,
            username: username,
            password: password,
            createdOn: createdOn
        )
    }
}

struct DecryptedPremiumProxy: Codable, Hashable {
    let ipID: Int
    let ipAddress: String
    let port: Int
    let username: String
    let password: String
    let createdOn: String

    enum CodingKeys: String, CodingKey {
        case ipID = "IP_ID"
        case ipAddress = "IP"
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
            host: ipAddress,
            port: UInt16(clamping: port),
            username: username,
            password: password
        )
    }
}
