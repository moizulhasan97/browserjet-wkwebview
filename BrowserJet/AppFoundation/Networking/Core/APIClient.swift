//
//  APIClient.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 24/02/2026.
//

import Foundation

final class APIClient {
    static let shared = APIClient()
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func request<T: Decodable>(_ endpoint: some EndpointProtocol, as type: T.Type) async throws -> T {
        let request = try endpoint.asURLRequest()
        let (data, response) = try await session.data(for: request)
        try validate(response)
        return try JSONDecoder().decode(T.self, from: data)
    }

    // For endpoints that return plain text instead of JSON (your server does this a lot)
    func requestText(_ endpoint: some EndpointProtocol) async throws -> String {
        let request = try endpoint.asURLRequest()
        let (data, response) = try await session.data(for: request)
        try validate(response)
        return String(decoding: data, as: UTF8.self)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // For raw Data (encrypted proxies)
    func requestData(_ endpoint: some EndpointProtocol) async throws -> Data {
        let request = try endpoint.asURLRequest()
        let (data, response) = try await session.data(for: request)
        try validate(response)
        return data
    }

    private func validate(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        switch http.statusCode {
        case 200...299: return
        case 401...500: throw APIError.unauthorized
        case 501...599: throw APIError.serverError
        default:        throw APIError.invalidResponse
        }
    }
}
