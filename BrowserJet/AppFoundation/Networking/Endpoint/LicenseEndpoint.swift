//
//  LicenseEndpoint.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 24/02/2026.
//

import Foundation

enum LicenseEndpoint: EndpointProtocol {

    case verifyKey(String)
    case generateKey(email: String, password: String)
    case checkExpiry(String)

    var baseURL: URL { APIEnvironment.current.baseURL }

    var path: String { "/License.ashx" }

    var method: HTTPMethod { .get }

    var queryItems: [URLQueryItem]? {
        switch self {
        case .verifyKey(let key):
            return [
                .init(name: "Method", value: "VerifyKey"),
                .init(name: "Key", value: key)
            ]
        case .generateKey(let email, let password):
            return [
                .init(name: "Method", value: "CreateKey"),
                .init(name: "Email", value: email),
                .init(name: "Password", value: password)
            ]
        case .checkExpiry(let key):
            return [
                .init(name: "Method", value: "CheckKeyExpiry"),
                .init(name: "Key", value: key)
            ]
        }
    }
}
