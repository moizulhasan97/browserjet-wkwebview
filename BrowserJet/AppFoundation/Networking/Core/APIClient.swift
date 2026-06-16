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
        logRequest(request)
        let (data, response) = try await session.data(for: request)
        try validate(response, data: data)
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
        logRequest(request)
        let (data, response) = try await session.data(for: request)
        try validate(response, data: data)
        let raw = String(bytes: data, encoding: .utf8) ?? ""
        return raw.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func requestData(_ endpoint: some EndpointProtocol) async throws -> Data {
        let request = try endpoint.asURLRequest()
        logRequest(request)
        let (data, response) = try await session.data(for: request)
        try validate(response, data: data)
        return data
    }

    // MARK: - Logging

    private func logRequest(_ request: URLRequest) {
        var lines: [String] = []
        lines.append("◆ REQUEST")
        lines.append("  Method  : \(request.httpMethod ?? "?")")
        lines.append("  URL     : \(request.url?.absoluteString ?? "unknown")")
        if let headers = request.allHTTPHeaderFields, !headers.isEmpty {
            lines.append("  Headers : \(headers)")
        }
        if let body = request.httpBody, let bodyString = String(data: body, encoding: .utf8) {
            lines.append("  Body    : \(bodyString)")
        }
        AppLogger.info(separator() + "\n" + lines.joined(separator: "\n"))
    }

    private func logResponse(statusCode: Int, body: String) {
        var lines: [String] = []
        lines.append("◆ RESPONSE")
        lines.append("  Status  : \(statusCode)")
        lines.append("  Body    : \(body.isEmpty ? "<empty>" : body)")
        AppLogger.info(lines.joined(separator: "\n") + "\n" + separator())
    }

    private func separator() -> String {
        "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    }

    // MARK: - Validation

    private func validate(_ response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else {
            AppLogger.error("APIClient invalid response - not an HTTPURLResponse")
            throw APIError.invalidResponse
        }
        let body = (String(bytes: data, encoding: .utf8) ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        logResponse(statusCode: http.statusCode, body: body)
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
