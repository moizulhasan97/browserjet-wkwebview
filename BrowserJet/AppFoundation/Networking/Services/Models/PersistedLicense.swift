//
//  PersistedLicense.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 24/02/2026.
//

import Foundation

struct PersistedLicense: Codable {
    let userEmail: String
    let authenticationType: String
    let userExpiryDate: Date
    let numberOfLicenses: Int
    let proxyEnabled: Bool
    let username: String
    let proxyPackage: Int
    let userKind: String

    let subscriptionTier: String
    let tierRawValue: String
    let has5TabTrialCode: Bool

    let trialExpired: Bool
    let userStatus: String
    let firstNotificationMessage: String
    let secondNotificationMessage: String
    let proxyExpiryDate: Date?

    init(_ response: VerifyKeyResponse) {
        let now = Date() // .toLocalTime()

        userEmail = response.userEmail
        authenticationType = response.authenticationType.rawValue
        userExpiryDate = response.userExpiryDate
        numberOfLicenses = response.numberOfLicenses
        proxyEnabled = response.proxyEnabled
        username = response.username
        proxyPackage = response.proxyPackage
        userKind = response.userKind.rawValue

        subscriptionTier = response.subscriptionTier.rawValue
        tierRawValue = response.tierRawValue
        has5TabTrialCode = response.has5TabTrialCode

        switch response.userKind {
        case .trial:
            trialExpired = response.has5TabTrialCode || response.isTrialAccessExpiredByProxyDate(referenceNow: now)
        case .paid:
            trialExpired = false
        }

        userStatus = response.userStatus.rawValue
        firstNotificationMessage = response.firstNotificationMessage
        secondNotificationMessage = response.secondNotificationMessage
        proxyExpiryDate = response.proxyExpiryDate
    }

    enum CodingKeys: String, CodingKey {
        case userEmail, authenticationType, userExpiryDate, numberOfLicenses
        case proxyEnabled, username, proxyPackage, userKind
        case subscriptionTier, tierRawValue, has5TabTrialCode
        case trialExpired, userStatus, firstNotificationMessage, secondNotificationMessage, proxyExpiryDate
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        userEmail = try container.decode(String.self, forKey: .userEmail)
        authenticationType = try container.decode(String.self, forKey: .authenticationType)
        userExpiryDate = try container.decode(Date.self, forKey: .userExpiryDate)
        numberOfLicenses = try container.decode(Int.self, forKey: .numberOfLicenses)
        proxyEnabled = try container.decode(Bool.self, forKey: .proxyEnabled)
        username = try container.decode(String.self, forKey: .username)
        proxyPackage = try container.decode(Int.self, forKey: .proxyPackage)
        userKind = try container.decode(String.self, forKey: .userKind)

        subscriptionTier = try container.decodeIfPresent(String.self, forKey: .subscriptionTier)
            ?? SubscriptionTier.unknown.rawValue
        tierRawValue = try container.decodeIfPresent(String.self, forKey: .tierRawValue) ?? ""
        has5TabTrialCode = try container.decodeIfPresent(Bool.self, forKey: .has5TabTrialCode) ?? false

        trialExpired = try container.decode(Bool.self, forKey: .trialExpired)
        userStatus = try container.decode(String.self, forKey: .userStatus)
        firstNotificationMessage = try container.decode(String.self, forKey: .firstNotificationMessage)
        secondNotificationMessage = try container.decode(String.self, forKey: .secondNotificationMessage)
        proxyExpiryDate = try container.decodeIfPresent(Date.self, forKey: .proxyExpiryDate)
    }

    func isEligibleForBackgroundLicenseMonitoring(referenceNow: Date = Date() ) -> Bool { // .toLocalTime()) -> Bool {
        guard let auth = AuthenticationType(rawValue: authenticationType), auth == .verified else { return false }
        guard let status = UserStatus(rawValue: userStatus), status == .active else { return false }

        switch UserKind(rawValue: userKind) ?? .trial {
        case .paid:
            return referenceNow <= userExpiryDate
        case .trial:
            if has5TabTrialCode { return false }
            if let proxyExpiryDate {
                return referenceNow <= proxyExpiryDate
            }
            return !trialExpired
        }
    }
}
