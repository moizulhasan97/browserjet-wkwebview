//
//  ProxyEndpoint.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 24/02/2026.
//

import Foundation

enum ProxyEndpoint: EndpointProtocol {

    case premium(key: String, email: String)
    case vpn1(key: String)

    var baseURL: URL { APIEnvironment.current.baseURL }
    var path: String { "/License.ashx" }
    var method: HTTPMethod { .get }

    var queryItems: [URLQueryItem]? {
        switch self {
        case .premium(let key, let email):
            return [
                .init(name: "Method", value: "GetPremiumProxies"),
                .init(name: "Key", value: key),
                .init(name: "Email", value: email)
            ]
        case .vpn1(let key):
            return [
                .init(name: "Method", value: "GetVPN1Proxies"),
                .init(name: "Key", value: key)
            ]
        }
    }
}
