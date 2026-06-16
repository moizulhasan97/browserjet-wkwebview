//
//  UserSession.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 25/02/2026.
//

import Foundation

struct UserSession {
    var userStatus: UserStatus = .rejected
    var userKind: UserKind = .trial
    var subscriptionTier: SubscriptionTier = .unknown
    var tierRawValue: String = ""

    var trialExpired: Bool = false
    var hasLicenseExpired: Bool = true
    var isPremiumProxyAllowed: Bool = false

    var shouldShowAllFeatures: Bool {
        !hasLicenseExpired && !trialExpired
    }

    var isTrialLockActive: Bool {
        trialExpired && userKind == .trial
    }
}

extension UserSession {
    init(
        responseModel: VerifyKeyResponse,
        store: KeyValueStoring
    ) throws {
        let now = Date() // .toLocalTime()
        userStatus = responseModel.userStatus
        userKind = responseModel.userKind
        subscriptionTier = responseModel.subscriptionTier
        tierRawValue = responseModel.tierRawValue
        isPremiumProxyAllowed = false

        switch responseModel.authenticationType {
        case .verified:
            switch responseModel.userStatus {
            case .rejected:
                break

            case .active:
                switch responseModel.userKind {
                case .trial:
                    let expiredBy5Tab = responseModel.has5TabTrialCode
                    let expiredByProxyDate = responseModel.isTrialAccessExpiredByProxyDate(referenceNow: now)
                    trialExpired = expiredBy5Tab || expiredByProxyDate
                    hasLicenseExpired = false

                case .paid:
                    trialExpired = false
                    hasLicenseExpired = responseModel.isUserLicenseExpired(referenceNow: now)
                }

                if hasLicenseExpired || trialExpired {
                    break
                }

                if responseModel.userKind == .paid {
                    isPremiumProxyAllowed = responseModel.proxyEnabled
                }
            }

        case .notVerified:
            let hasStoredKey = store.object(forKey: StorageKeys.licenseKey) != nil
            switch hasStoredKey {
            case false:
                throw AppError.notVerified
            case true:
                hasLicenseExpired = true
                trialExpired = false
            }
        }
    }
}
