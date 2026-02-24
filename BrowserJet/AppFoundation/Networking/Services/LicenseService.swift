//
//  LicenseService.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 24/02/2026.
//

import Foundation

final class LicenseService {
    private let client: APIClient

    init(client: APIClient = .shared) {
        self.client = client
    }

    func verifyKey(_ key: String) async throws -> VerifyKeyResponse {
        let data = try await client.requestData(LicenseEndpoint.verifyKey(key))
        return VerifyKeyResponse(csvData: data)
    }

    func generateKey(email: String, password: String) async throws -> String {
        let raw = try await client.requestText(LicenseEndpoint.generateKey(email: email, password: password))
        if raw.lowercased().trimmingCharacters(in: .whitespaces) == "duplicateemail" {
            throw APIError.duplicateEmail
        }
        return raw
    }

    func checkKeyExpiry(_ key: String) async throws -> Bool {
        let raw = try await client.requestText(LicenseEndpoint.checkExpiry(key))
        return raw.lowercased() == "true"
    }
}
