//
//  APIEnvironment.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 24/02/2026.
//

import Foundation

enum APIEnvironment {
    case production
    case development

    /// Compile-time-safe URL constant. The literal is hard-coded and verified to parse,
    /// so the otherwise-`Optional<URL>` initializer can never fail at runtime.
    private static let serviceBaseURL: URL = {
        guard let url = URL(string: "https://service.browserjet.com") else {
            preconditionFailure("Hard-coded service base URL must be valid")
        }
        return url
    }()

    var baseURL: URL {
        switch self {
        case .production, .development:
            return Self.serviceBaseURL
        }
    }

    static var current: APIEnvironment {
        AppEnvironment.current == .production ? .production : .development
    }
}
