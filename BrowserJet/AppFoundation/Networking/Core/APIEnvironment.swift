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

    var baseURL: URL {
        switch self {
        case .production, .development:
            return URL(string: "https://service.browserjet.com")!
        }
    }

    static var current: APIEnvironment {
        AppEnvironment.current == .production ? .production : .development
    }
}
