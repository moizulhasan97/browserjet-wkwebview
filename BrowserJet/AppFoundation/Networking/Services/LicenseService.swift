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
        AppLogger.info("LicenseService: verifying key '\(key)'")
        do {
            let data = try await client.requestData(LicenseEndpoint.verifyKey(key))
            let response = VerifyKeyResponse(csvData: data)
            AppLogger.info("LicenseService: key verified - status: \(response.authenticationType.rawValue), email: \(response.userEmail)")
            return response
        } catch {
            AppLogger.error("LicenseService: verifyKey failed - \(error.localizedDescription)")
            throw error
        }
    }

    func generateKey(email: String, password: String) async throws -> String {
        AppLogger.info("LicenseService: generating key for email '\(email)'")
        do {
            let raw = try await client.requestText(LicenseEndpoint.generateKey(email: email, password: password))
            if raw.lowercased().trimmingCharacters(in: .whitespaces) == "duplicateemail" {
                AppLogger.warning("LicenseService: generateKey rejected - duplicate email '\(email)'")
                throw APIError.duplicateEmail
            }
            AppLogger.info("LicenseService: key generated successfully for '\(email)'")
            return raw
        } catch {
            AppLogger.error("LicenseService: generateKey failed - \(error.localizedDescription)")
            throw error
        }
    }

    func checkKeyExpiry(_ key: String) async throws -> Bool {
        AppLogger.info("LicenseService: checking expiry for key '\(key)'")
        do {
            let raw = try await client.requestText(LicenseEndpoint.checkExpiry(key))
            let isExpired = raw.lowercased() == "true"
            AppLogger.info("LicenseService: key expiry check - expired: \(isExpired)")
            return isExpired
        } catch {
            AppLogger.error("LicenseService: checkKeyExpiry failed - \(error.localizedDescription)")
            throw error
        }
    }
}
