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
            let pcName = SystemInfo.currentComputerName()
            let mac = SystemInfo.macSerialNumber()
            let endpoint = LicenseEndpoint.verifyKey(key: key, pcName: pcName, macAddress: mac)
            let data = try await client.requestData(endpoint)
            let rawCSV = String(bytes: data, encoding: .utf8) ?? ""
            AppLogger.info("LicenseService: raw CSV response → \(rawCSV)")
            let response = VerifyKeyResponse(csvData: data)
            AppLogger.info(
                """
                LicenseService: parsed response →
                auth: \(response.authenticationType.rawValue) | \
                email: \(response.userEmail) | \
                kind: \(response.userKind.rawValue) | \
                status: \(response.userStatus.rawValue) | \
                expiry: \(response.userExpiryDate) | \
                licenses: \(response.numberOfLicenses)
                """
            )
            return response
        } catch {
            AppLogger.error("LicenseService: verifyKey failed - \(error.localizedDescription)")
            throw error
        }
    }

    /// `UpdateToMac` — same rules as legacy `shouldUpdateKey`: run unless stored value is `true`.
    /// Non-fatal: on failure stores `false` so the next verify retries.
    func updateKeyInBackendIfNeeded(key: String, keyValueStore: KeyValueStoring) async {
        guard Self.shouldRunUpdateToMac(store: keyValueStore) else {
            AppLogger.debug("LicenseService: skipping UpdateToMac (already succeeded for this cycle)")
            return
        }
        do {
            _ = try await client.requestData(LicenseEndpoint.updateToDatabase(key: key))
            keyValueStore.set(true, forKey: StorageKeys.updateKeyInDatabase)
            AppLogger.info("LicenseService: UpdateToMac completed successfully")
        } catch {
            keyValueStore.set(false, forKey: StorageKeys.updateKeyInDatabase)
            AppLogger.warning("LicenseService: UpdateToMac failed (non-fatal) — \(error.localizedDescription)")
        }
    }

    private static func shouldRunUpdateToMac(store: KeyValueStoring) -> Bool {
        guard let succeeded = store.object(forKey: StorageKeys.updateKeyInDatabase) as? Bool else {
            return true
        }
        return !succeeded
    }

    func requestPasswordReset(email: String) async throws {
        AppLogger.info("LicenseService: requestPasswordReset for '\(email)'")
        let raw = try await client.requestText(LicenseEndpoint.forgotPassword(email: email))
        let normalized = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalized == "EmailSent" else {
            AppLogger.warning("LicenseService: requestPasswordReset unexpected body → \(raw)")
            throw APIError.custom("We couldn’t send the email. Please try again.")
        }
        AppLogger.info("LicenseService: requestPasswordReset — EmailSent")
    }

    func generateKey(email: String, password: String) async throws -> String {
        AppLogger.info("LicenseService: generating key for email '\(email)'")
        do {
            let raw = try await client.requestText(LicenseEndpoint.generateKey(email: email, password: password))
            let normalized = raw.lowercased()
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .filter { !$0.isWhitespace }
            if normalized == "duplicateemail" {
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

    func getPCDetails(key: String) async throws -> String {
        let raw = try await client.requestText(LicenseEndpoint.getOldPCDetails(key))
        let pcName = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPcName = String(pcName.dropLast())
        return trimmedPcName
    }

    private func updateUserMachine(oldPcName: String, key: String, email: String) async throws {
        let payload = LicenseEndpoint.ShiftPayload(
            key: key,
            newPcName: SystemInfo.currentComputerName(),
            newMacAddress: SystemInfo.macSerialNumber(),
            email: email,
            oldPcName: oldPcName
        )
        let raw = try await client.requestText(LicenseEndpoint.shiftLicenseKey(payload))
        let response = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if response != "shited" {
            throw APIError.custom("Shift failed: \(raw)")
        }
    }

    private func sendEmailToUser(oldPcName: String, key: String, email: String) async throws {
        let payload = LicenseEndpoint.ShiftPayload(
            key: key,
            newPcName: SystemInfo.currentComputerName(),
            newMacAddress: SystemInfo.macSerialNumber(),
            email: email,
            oldPcName: oldPcName
        )
        _ = try await client.requestText(LicenseEndpoint.sendEmailToUser(payload))
    }

    func shiftKey(from oldPcName: String, key: String, email: String) async throws {
        try await updateUserMachine(oldPcName: oldPcName, key: key, email: email)
        try await sendEmailToUser(oldPcName: oldPcName, key: key, email: email)
    }
}
