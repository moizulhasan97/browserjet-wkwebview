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
        let raw = String(decoding: csvData, as: UTF8.self)
        let components = raw.components(separatedBy: ",")
        
        for (index, value) in components.enumerated() {
            guard let field = Field(rawValue: index) else { continue }
            
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            let lowercased = trimmed.lowercased()
            
            switch field {
            case .authenticationType:
                guard !trimmed.isEmpty else { continue }
                authenticationType = AuthenticationType(rawValue: lowercased) ?? .notVerified
                if authenticationType == .notVerified { return }
                
            case .userExpiryDate:
                guard !trimmed.isEmpty else { continue }
                userExpiryDate = DateFormatterProvider.date(from: trimmed) ?? .init()
                
            case .version:
                guard !trimmed.isEmpty else { continue }
                version = Double(trimmed) ?? 0.0
                
            case .numberOfLicenses:
                guard !trimmed.isEmpty else { continue }
                numberOfLicenses = Int(trimmed) ?? 0
                
            case .userEmail:
                guard !trimmed.isEmpty else { continue }
                userEmail = trimmed
                
            case .proxyEnabled:
                guard !trimmed.isEmpty else { continue }
                proxyEnabled = lowercased == "true"
                
            case .username:
                guard !trimmed.isEmpty else { continue }
                username = trimmed
                
            case .proxyPackage:
                guard !trimmed.isEmpty else { continue }
                proxyPackage = Int(trimmed) ?? 0
                
            case .proxyExpiryDate:
                guard !trimmed.isEmpty else { continue }
                proxyExpiryDate = DateFormatterProvider.date(from: trimmed) ?? .init()
                
            case .proxyTestDate:
                guard !trimmed.isEmpty else { continue }
                proxyTestDate = DateFormatterProvider.date(from: trimmed) ?? .init()
                
            case .userKind:
                guard !trimmed.isEmpty else { continue }
                userKind = UserKind(rawValue: lowercased) ?? .trial
                
            case .tierCode:
                // Must parse even when empty (paid empty => .pro)
                tierRawValue = trimmed
                has5TabTrialCode = (lowercased == "5tab")
                subscriptionTier = SubscriptionTier.fromBackend(rawValue: trimmed, userKind: userKind)
                
            case .firstNotificationMessage:
                guard !trimmed.isEmpty else { continue }
                firstNotificationMessage = trimmed
                
            case .secondNotificationMessage:
                guard !trimmed.isEmpty else { continue }
                secondNotificationMessage = trimmed
                
            case .userStatus:
                guard !trimmed.isEmpty else { continue }
                userStatus = UserStatus(rawValue: lowercased) ?? .rejected
            }
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
