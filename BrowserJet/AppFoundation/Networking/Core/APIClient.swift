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
        AppLogger.info("APIClient [\(request.httpMethod ?? "?")] \(request.url?.absoluteString ?? "unknown URL")")
        let (data, response) = try await session.data(for: request)
        try validate(response)
        AppLogger.debug("APIClient response received - decoding as \(T.self)")
        do {
            let decoded = try JSONDecoder().decode(T.self, from: data)
            AppLogger.info("APIClient decode success - \(T.self)")
            return decoded
        } catch {
            AppLogger.error("APIClient decode failed - \(T.self): \(error.localizedDescription)")
            throw error
        }
    }

    func requestText(_ endpoint: some EndpointProtocol) async throws -> String {
        let request = try endpoint.asURLRequest()
        AppLogger.info("APIClient [\(request.httpMethod ?? "?")] \(request.url?.absoluteString ?? "unknown URL") → text")
        let (data, response) = try await session.data(for: request)
        try validate(response)
        let text = String(decoding: data, as: UTF8.self)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        AppLogger.debug("APIClient text response: \"\(text)\"")
        return text
    }

    func requestData(_ endpoint: some EndpointProtocol) async throws -> Data {
        let request = try endpoint.asURLRequest()
        AppLogger.info("APIClient [\(request.httpMethod ?? "?")] \(request.url?.absoluteString ?? "unknown URL") → data")
        let (data, response) = try await session.data(for: request)
        try validate(response)
        AppLogger.debug("APIClient data response - \(data.count) bytes")
        return data
    }

    private func validate(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else {
            AppLogger.error("APIClient invalid response - not an HTTPURLResponse")
            throw APIError.invalidResponse
        }
        AppLogger.debug("APIClient HTTP status: \(http.statusCode)")
        switch http.statusCode {
        case 200...299:
            return
        case 401...500:
            AppLogger.warning("APIClient unauthorized - HTTP \(http.statusCode)")
            throw APIError.unauthorized
        case 501...599:
            AppLogger.error("APIClient server error - HTTP \(http.statusCode)")
            throw APIError.serverError
        default:
            AppLogger.error("APIClient unexpected status - HTTP \(http.statusCode)")
            throw APIError.invalidResponse
        }
    }
}
