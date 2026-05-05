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
    let trialExpired: Bool
    let userStatus: String
    let firstNotificationMessage: String
    let secondNotificationMessage: String
    let proxyExpiryDate: Date?
    
    init(_ response: VerifyKeyResponse) {
        let now = Date().toLocalTime()
        userEmail = response.userEmail
        authenticationType = response.authenticationType.rawValue
        userExpiryDate = response.userExpiryDate
        numberOfLicenses = response.numberOfLicenses
        proxyEnabled = response.proxyEnabled
        username = response.username
        proxyPackage = response.proxyPackage
        userKind = response.userKind.rawValue
        trialExpired = response.isTrialAccessExpiredByProxyDate(referenceNow: now)
        userStatus = response.userStatus.rawValue
        firstNotificationMessage = response.firstNotificationMessage
        secondNotificationMessage = response.secondNotificationMessage
        proxyExpiryDate = response.proxyExpiryDate
    }
    
    /// Whether browser license checks should run
    func isEligibleForBackgroundLicenseMonitoring(referenceNow: Date = Date().toLocalTime()) -> Bool {
        guard let auth = AuthenticationType(rawValue: authenticationType), auth == .verified else { return false }
        guard let status = UserStatus(rawValue: userStatus), status == .active else { return false }
        guard referenceNow <= userExpiryDate else { return false }
        switch UserKind(rawValue: userKind) ?? .trial {
        case .paid:
            return true
        case .trial:
            if let proxyExpiryDate {
                return referenceNow <= proxyExpiryDate
            }
            return !trialExpired
        }
    }
}
