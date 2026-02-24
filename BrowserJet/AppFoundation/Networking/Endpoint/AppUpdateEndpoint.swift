//
//  AppUpdateEndpoint.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 24/02/2026.
//


import Foundation

enum AppUpdateEndpoint: EndpointProtocol {

    case latestVersion

    var baseURL: URL { APIEnvironment.current.baseURL }

    var path: String { "/License.ashx" }

    var method: HTTPMethod { .get }

    var queryItems: [URLQueryItem]? {
        switch self {
        case .latestVersion:
            return [.init(name: "Method", value: "GetMacVersion")]
        }
    }
}