//
//  ProxyEndpoint.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 24/02/2026.
//

import Foundation

enum ProxyEndpoint: EndpointProtocol {

    case premium(key: String)
    case vpn1(key: String)

    var baseURL: URL { APIEnvironment.current.baseURL }
    var path: String { "/License.ashx" }
    var method: HTTPMethod { .get }

    var queryItems: [URLQueryItem]? {
        switch self {
        case .premium(let key):
            return [
                .init(name: "MethodName", value: "GPP"),
                .init(name: "Key", value: key),
                .init(name: "RequestFrom", value: "Mac")
            ]
        case .vpn1(let key):
            return [
                .init(name: "MethodName", value: "VPR"),
                .init(name: "Key", value: key),
                .init(name: "RequestFrom", value: "Mac")
            ]
        }
    }
}
