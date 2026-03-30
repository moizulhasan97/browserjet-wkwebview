//
//  LicenseActivationCoordinator.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 25/03/2026.
//

import Foundation

final class LicenseActivationCoordinator {

    private let licenseService: LicenseService
    private let licenseStore: LicenseStore
    private let keyValueStore: KeyValueStoring

    init(
        licenseService: LicenseService = LicenseService(),
        licenseStore: LicenseStore = LicenseStore(),
        keyValueStore: KeyValueStoring = UserDefaultsKeyValueStore()
    ) {
        self.licenseService = licenseService
        self.licenseStore = licenseStore
        self.keyValueStore = keyValueStore
    }

    func generateKeyAndActivate(email: String, password: String) async throws -> VerifyOutcome {
        let key = try await licenseService.generateKey(email: email, password: password)
        return try await completeActivation(key: key)
    }

    func completeActivation(key: String) async throws -> VerifyOutcome {
        let response = try await licenseService.verifyKey(key)

        if let previousKey = keyValueStore.object(forKey: StorageKeys.licenseKey) as? String, previousKey != key {
            keyValueStore.removeObject(forKey: StorageKeys.updateKeyInDatabase)
            // TODO: Full “change key” UX — invalidate any data tied to the old license before saving the new one.
            await MainActor.run {
                PremiumProxyRepository.shared.clearForLicenseChange()
            }
        }

        let userSession = try UserSession(responseModel: response, store: keyValueStore)

        licenseStore.save(response)
        await MainActor.run {
            LicenseAccountStore.shared.refresh()
        }

        keyValueStore.set(key, forKey: StorageKeys.licenseKey)
        keyValueStore.set(response.userEmail, forKey: StorageKeys.userEmail)

        await licenseService.updateKeyInBackendIfNeeded(key: key, keyValueStore: keyValueStore)

        if userSession.userStatus == .rejected {
            return .shiftRequired(key: key, email: response.userEmail)
        }

        let emailForURL = (keyValueStore.object(forKey: StorageKeys.userEmail) as? String) ?? response.userEmail
        let paymentURL = LicenseEndpoint.licenseExpiredPaymentURL(email: emailForURL)

        if userSession.trialExpired {
            AppLogger.info("PAYMENT URL FOR TRIAL EXPIRED: \(paymentURL)")
            return .trialExpired(paymentURL: paymentURL)
        }
        if userSession.hasLicenseExpired {
            AppLogger.info("PAYMENT URL FOR LICENSE EXPIRED: \(paymentURL)")
            return .licenseExpired(paymentURL: paymentURL)
        }
        return .success
    }
}
