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

    init(_ response: VerifyKeyResponse) {
        userEmail = response.userEmail
        authenticationType = response.authenticationType.rawValue
        userExpiryDate = response.userExpiryDate
        numberOfLicenses = response.numberOfLicenses
        proxyEnabled = response.proxyEnabled
        username = response.username
        proxyPackage = response.proxyPackage
        userKind = response.userKind.rawValue
        trialExpired = response.trialExpired
        userStatus = response.userStatus.rawValue
        firstNotificationMessage = response.firstNotificationMessage
        secondNotificationMessage = response.secondNotificationMessage
    }
}
