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
            let data = try await client.requestData(LicenseEndpoint.verifyKey(key: key, pcName: pcName, macAddress: mac))
            let rawCSV = String(decoding: data, as: UTF8.self)
            AppLogger.info("LicenseService: raw CSV response → \(rawCSV)")
            let response = VerifyKeyResponse(csvData: data)
            AppLogger.info("LicenseService: parsed response → auth: \(response.authenticationType.rawValue) | email: \(response.userEmail) | kind: \(response.userKind.rawValue) | status: \(response.userStatus.rawValue) | expiry: \(response.userExpiryDate) | licenses: \(response.numberOfLicenses)")
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
    
    func getPCDetails(key: String) async throws -> String {
        let raw = try await client.requestText(LicenseEndpoint.getOldPCDetails(key))
        let pcName = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPcName = String(pcName.dropLast())
        return trimmedPcName
    }
    
    private func updateUserMachine(oldPcName: String, key: String, email: String) async throws {
        let newPcName = SystemInfo.currentComputerName()
        let newMacAddress = SystemInfo.macSerialNumber()
        let raw = try await client.requestText(LicenseEndpoint.shiftLicenseKey(
            key: key,
            newPcName: newPcName,
            newMacAddress: newMacAddress,
            email: email,
            oldPcName: oldPcName
        ))
        let response = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if response != "shited" {
            throw APIError.custom("Shift failed: \(raw)")
        }
    }
    
    private func sendEmailToUser(oldPcName: String, key: String, email: String) async throws {
        let newPcName = SystemInfo.currentComputerName()
        let newMacAddress = SystemInfo.macSerialNumber()
        _ = try await client.requestText(LicenseEndpoint.sendEmailToUser(
            key: key,
            newPcName: newPcName,
            newMacAddress: newMacAddress,
            email: email,
            oldPcName: oldPcName
        ))
    }
    
    func shiftKey(from oldPcName: String, key: String, email: String) async throws {
        try await updateUserMachine(oldPcName: oldPcName, key: key, email: email)
        try await sendEmailToUser(oldPcName: oldPcName, key: key, email: email)
    }
}
