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
    /// Builds session from verify-key API response. Throws if not verified and no stored key.
    init(
        responseModel: VerifyKeyResponse,
        store: KeyValueStoring
    ) throws {
        let now = Date().toLocalTime()
        userStatus = responseModel.userStatus
        userKind = responseModel.userKind
        isPremiumProxyAllowed = false

        switch responseModel.authenticationType {

        case .verified:
            switch responseModel.userStatus {

            case .rejected:
                break
                
            case .active:
                hasLicenseExpired = responseModel.isUserLicenseExpired(referenceNow: now)
                trialExpired = responseModel.isTrialAccessExpiredByProxyDate(referenceNow: now)

                if hasLicenseExpired {
                    break
                }
                switch responseModel.userKind {
                case .paid:
                    isPremiumProxyAllowed = responseModel.proxyEnabled
                case .trial:
                    isPremiumProxyAllowed = false
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
