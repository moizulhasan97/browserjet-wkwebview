//
//  EndpointProtocol.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 24/02/2026.
//

import Foundation

protocol EndpointProtocol {
    var baseURL: URL { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var queryItems: [URLQueryItem]? { get }
    var body: Data? { get }
    var headers: [String: String] { get }
}

extension EndpointProtocol {
    // Sensible defaults — most endpoints only override what they need
    var queryItems: [URLQueryItem]? { nil }
    var body: Data? { nil }
    var headers: [String: String] { [:] }

    func asURLRequest() throws -> URLRequest {
        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)
        components?.queryItems = queryItems
        guard let url = components?.url else { throw APIError.invalidURL }

        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 60)
        request.httpMethod = method.rawValue
        request.httpBody = body
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        return request
    }
}
