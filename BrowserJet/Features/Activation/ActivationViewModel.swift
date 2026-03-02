//
//  ActivationViewModel.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 22/02/2026.
//

import SwiftUI

// MARK: - Verify outcome (post-verify routing)

enum VerifyOutcome: Equatable {
    case success
    case shiftRequired(key: String, email: String)
    case trialExpired(paymentURL: URL)
    case licenseExpired(paymentURL: URL)
}

@MainActor
final class ActivationViewModel: ObservableObject {

    enum Mode: String, CaseIterable, Hashable {
        case activate
        case register

        var displayLabel: String {
            switch self {
            case .activate: return ActivationMessages.Mode.useKey
            case .register: return ActivationMessages.Mode.register
            }
        }

        var buttonTitle: String {
            switch self {
            case .activate: return ActivationMessages.Mode.verifyButton
            case .register: return ActivationMessages.Mode.createKeyButton
            }
        }
    }

    /// Base URL for trial-expired payment flow (append email as query when needed).
    //private static let trialExpiredPaymentBase = "https://browserjet.com/trial-expired"

    // MARK: - Dependencies

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

    // MARK: - State

    @Published var mode: Mode = .activate

    // Activate
    @Published var licenseKey: String = ""

    // Register
    @Published var email: String = ""
    @Published var password: String = ""
    
    // Validation
    @Published var licenseKeyValidation: RegexValidationState = .none
    @Published var emailValidation: RegexValidationState = .none
    @Published var passwordValidation: RegexValidationState = .none

    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    /// Set after verify success; view observes and handles success / shift / trial-expired.
    @Published var verifyOutcome: VerifyOutcome? = nil

    var canSubmit: Bool {
        switch mode {
        case .activate:
            return licenseKeyValidation == .valid
        case .register:
            return emailValidation == .valid && passwordValidation == .valid
        }
    }

    // MARK: - Actions

    func submit() {
        Task {
            isLoading = true
            errorMessage = nil
            verifyOutcome = nil
            defer { isLoading = false }

            do {
                switch mode {
                case .activate:
                    try await runVerifyAndRoute(key: licenseKey)
                case .register:
                    let key = try await licenseService.generateKey(email: email, password: password)
                    try await runVerifyAndRoute(key: key)
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    /// Re-run verify with the same key after user completes Shift PC flow; then route again.
    func completeShiftAndRetryVerify(key: String) {
        Task {
            isLoading = true
            errorMessage = nil
            verifyOutcome = nil
            defer { isLoading = false }
            do {
                try await runVerifyAndRoute(key: key)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func forgotPasswordTapped() {
        // TODO: open URL or in-app flow
        print("🔗 Forgot password tapped")
    }

    // MARK: - Verify + persist + route

    private func runVerifyAndRoute(key: String) async throws {
        let response = try await licenseService.verifyKey(key)

        licenseStore.save(response)
        keyValueStore.set(key, forKey: StorageKeys.licenseKey)
        keyValueStore.set(response.userEmail, forKey: StorageKeys.userEmail)

        let userSession = try UserSession(responseModel: response, store: keyValueStore)

        if userSession.userStatus == .rejected {
            verifyOutcome = .shiftRequired(key: key, email: response.userEmail)
            return
        }
        let emailForURL = (keyValueStore.object(forKey: StorageKeys.userEmail) as? String) ?? response.userEmail
        let paymentURL = LicenseEndpoint.licenseExpiredPaymentURL(email: emailForURL)

        if userSession.trialExpired {
            AppLogger.info("PAYMENT URL FOR TRIAL EXPIRED: \(paymentURL)")
            verifyOutcome = .trialExpired(paymentURL: paymentURL)
            return
        }
        if userSession.hasLicenseExpired {
            AppLogger.info("PAYMENT URL FOR LICENSE EXPIRED: \(paymentURL)")
            verifyOutcome = .licenseExpired(paymentURL: paymentURL)
            return
        }
        verifyOutcome = .success
    }
}

// MARK: - URL query encoding


