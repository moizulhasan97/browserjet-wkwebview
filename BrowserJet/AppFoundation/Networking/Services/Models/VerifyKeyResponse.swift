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
    var firstNotificationMessage: String = ""
    var secondNotificationMessage: String = ""
    var userStatus: UserStatus = .rejected
    // New package/tier fields
    var subscriptionTier: SubscriptionTier = .unknown
    var tierRawValue: String = ""
    var has5TabTrialCode: Bool = false

    init(csvData: Data) {
        let raw = String(bytes: csvData, encoding: .utf8) ?? ""
        let components = raw.components(separatedBy: ",")

        for (index, value) in components.enumerated() {
            guard let field = Field(rawValue: index) else { continue }
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            let shouldStop = applyField(field, trimmed: trimmed)
            if shouldStop { return }
        }
    }

    /// Applies a single CSV field. Returns `true` when parsing should stop early
    /// (currently only when authentication is reported as `notVerified`).
    private mutating func applyField(_ field: Field, trimmed: String) -> Bool {
        let lowercased = trimmed.lowercased()

        if let stop = applyAuthenticationField(field, trimmed: trimmed, lowercased: lowercased) {
            return stop
        }
        applyUserBasicsField(field, trimmed: trimmed, lowercased: lowercased)
        applyProxyField(field, trimmed: trimmed, lowercased: lowercased)
        applyTierField(field, trimmed: trimmed, lowercased: lowercased)
        applyNotificationField(field, trimmed: trimmed, lowercased: lowercased)
        return false
    }

    /// Returns `nil` when the field is not part of this group; otherwise a Bool indicating whether to stop parsing.
    private mutating func applyAuthenticationField(
        _ field: Field, trimmed: String, lowercased: String
    ) -> Bool? {
        switch field {
        case .authenticationType:
            guard !trimmed.isEmpty else { return false }
            authenticationType = AuthenticationType(rawValue: lowercased) ?? .notVerified
            return authenticationType == .notVerified
        case .userStatus:
            guard !trimmed.isEmpty else { return false }
            userStatus = UserStatus(rawValue: lowercased) ?? .rejected
            return false
        case .userKind:
            guard !trimmed.isEmpty else { return false }
            userKind = UserKind(rawValue: lowercased) ?? .trial
            return false
        default:
            return nil
        }
    }

    private mutating func applyUserBasicsField(
        _ field: Field, trimmed: String, lowercased: String
    ) {
        guard !trimmed.isEmpty else { return }
        switch field {
        case .userExpiryDate:
            userExpiryDate = DateFormatterProvider.date(from: trimmed) ?? .init()
        case .version:
            version = Double(trimmed) ?? 0.0
        case .numberOfLicenses:
            numberOfLicenses = Int(trimmed) ?? 0
        case .userEmail:
            userEmail = trimmed
        case .username:
            username = trimmed
        default:
            break
        }
    }

    private mutating func applyProxyField(
        _ field: Field, trimmed: String, lowercased: String
    ) {
        guard !trimmed.isEmpty else { return }
        switch field {
        case .proxyEnabled:
            proxyEnabled = lowercased == "true"
        case .proxyPackage:
            proxyPackage = Int(trimmed) ?? 0
        case .proxyExpiryDate:
            proxyExpiryDate = DateFormatterProvider.date(from: trimmed) ?? .init()
        case .proxyTestDate:
            proxyTestDate = DateFormatterProvider.date(from: trimmed) ?? .init()
        default:
            break
        }
    }

    private mutating func applyTierField(
        _ field: Field, trimmed: String, lowercased: String
    ) {
        // Must parse even when empty (paid empty => .pro)
        guard field == .tierCode else { return }
        tierRawValue = trimmed
        has5TabTrialCode = (lowercased == "5tab")
        subscriptionTier = SubscriptionTier.fromBackend(rawValue: trimmed, userKind: userKind)
    }

    private mutating func applyNotificationField(
        _ field: Field, trimmed: String, lowercased: String
    ) {
        guard !trimmed.isEmpty else { return }
        switch field {
        case .firstNotificationMessage:
            firstNotificationMessage = trimmed
        case .secondNotificationMessage:
            secondNotificationMessage = trimmed
        default:
            break
        }
    }
}

extension VerifyKeyResponse {
    func isUserLicenseExpired(referenceNow: Date) -> Bool {
        !(referenceNow <= userExpiryDate)
    }

    func isTrialAccessExpiredByProxyDate(referenceNow: Date) -> Bool {
        switch userKind {
        case .paid:
            return false
        case .trial:
            return !(referenceNow <= proxyExpiryDate)
        }
    }
}

private extension VerifyKeyResponse {
    enum Field: Int {
        case authenticationType        = 0
        case userExpiryDate            = 1
        case version                   = 2
        case numberOfLicenses          = 3
        case userEmail                 = 4
        case proxyEnabled              = 5
        case username                  = 6
        case proxyPackage              = 7
        case proxyExpiryDate           = 8
        case proxyTestDate             = 9
        case userKind                  = 10
        case tierCode                  = 11
        case firstNotificationMessage  = 12
        case secondNotificationMessage = 13
        case userStatus                = 14
    }
}
