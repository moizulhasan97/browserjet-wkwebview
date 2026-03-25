//
//  VerifyKeyResponse.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 24/02/2026.
//


import Foundation

struct VerifyKeyResponse {

    var authenticationType: AuthenticationType = .notVerified
    var userExpiryDate: Date = .init()
    var version: Double = 0.0
    var numberOfLicenses: Int = 0
    var userEmail: String = ""
    var proxyEnabled: Bool = false
    var username: String = ""
    var proxyPackage: Int = 0
    var proxyExpiryDate: Date = .init()
    var proxyTestDate: Date = .init()
    var userKind: UserKind = .trial
    var trialExpired: Bool = true
    var firstNotificationMessage: String = ""
    var secondNotificationMessage: String = ""
    var userStatus: UserStatus = .rejected

    // MARK: - CSV Parsing
    init(csvData: Data) {
        let raw = String(decoding: csvData, as: UTF8.self)
        let components = raw.components(separatedBy: ",")

        for (index, value) in components.enumerated() {
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            let lowercased = trimmed.lowercased()

            guard !trimmed.isEmpty, let field = Field(rawValue: index) else { continue }

            switch field {
            case .authenticationType:
                authenticationType = AuthenticationType(rawValue: lowercased) ?? .notVerified
                // If not verified, remaining fields are irrelevant
                if authenticationType == .notVerified { return }

            case .userExpiryDate:
                userExpiryDate = DateFormatterProvider.date(from: trimmed) ?? .init()

            case .version:
                version = Double(trimmed) ?? 0.0

            case .numberOfLicenses:
                numberOfLicenses = Int(trimmed) ?? 0

            case .userEmail:
                userEmail = trimmed

            case .proxyEnabled:
                proxyEnabled = lowercased == "true"

            case .username:
                username = trimmed

            case .proxyPackage:
                proxyPackage = Int(trimmed) ?? 0

            case .proxyExpiryDate:
                proxyExpiryDate = DateFormatterProvider.date(from: trimmed) ?? .init()

            case .proxyTestDate:
                proxyTestDate = DateFormatterProvider.date(from: trimmed) ?? .init()

            case .userKind:
                userKind = UserKind(rawValue: lowercased) ?? .trial

            case .trialExpired:
                trialExpired = lowercased == "true"

            case .firstNotificationMessage:
                firstNotificationMessage = trimmed

            case .secondNotificationMessage:
                secondNotificationMessage = trimmed

            case .userStatus:
                userStatus = UserStatus(rawValue: lowercased) ?? .rejected
            }
        }
    }
}

// MARK: - Derived expiry (client-side; do not use raw API `trialExpired` for routing)

extension VerifyKeyResponse {

    /// For paid users, compare license expiry
    func isUserLicenseExpired(referenceNow: Date) -> Bool {
        !(referenceNow <= userExpiryDate)
    }

    /// For trial users, compare prixy expiry
    func isTrialAccessExpiredByProxyDate(referenceNow: Date) -> Bool {
        switch userKind {
        case .paid:
            return false
        case .trial:
            return !(referenceNow <= proxyExpiryDate)
        }
    }
}

// MARK: - Field Index Map
private extension VerifyKeyResponse {

    /// Maps the positional CSV index to a named field.
    /// Order must exactly match what the server returns.
    enum Field: Int {
        case authenticationType       = 0
        case userExpiryDate           = 1
        case version                  = 2
        case numberOfLicenses         = 3
        case userEmail                = 4
        case proxyEnabled             = 5
        case username                 = 6
        case proxyPackage             = 7
        case proxyExpiryDate          = 8
        case proxyTestDate            = 9
        case userKind                 = 10
        case trialExpired             = 11
        case firstNotificationMessage = 12
        case secondNotificationMessage = 13
        case userStatus               = 14
    }
}
