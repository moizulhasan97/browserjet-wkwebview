//
//  ActivationViewModel.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 22/02/2026.
//

import SwiftUI

// MARK: - Verify outcome (post-verify routing)

import Foundation

enum VerifyOutcome: Equatable {
    case success
    case shiftRequired(key: String, email: String)
    case trialExpired(paymentURL: URL)
    case licenseExpired(paymentURL: URL)
}

@MainActor
final class ActivationViewModel: ObservableObject {
    // MARK: - Dependencies

    private let coordinator: LicenseActivationCoordinator

    init(coordinator: LicenseActivationCoordinator = LicenseActivationCoordinator()) {
        self.coordinator = coordinator
    }

    // MARK: - State

    @Published var licenseKey: String = ""

    @Published var email: String = ""
    @Published var password: String = ""

    @Published var licenseKeyValidation: RegexValidationState = .none
    @Published var emailValidation: RegexValidationState = .none
    @Published var passwordValidation: RegexValidationState = .none

    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    @Published var verifyOutcome: VerifyOutcome?

    @Published var showRecoverAccountSheet: Bool = false

    // MARK: - Validation

    var canVerifyKey: Bool {
        licenseKeyValidation == .valid
    }

    var canCreateKey: Bool {
        emailValidation == .valid && passwordValidation == .valid
    }

    // MARK: - Actions

    func verifyKey() {
        guard canVerifyKey else { return }

        Task {
            isLoading = true
            errorMessage = nil
            verifyOutcome = nil

            defer { isLoading = false }

            AnalyticsManager.shared.log(.licenseVerifyAttempted)
            do {
                let key = licenseKey.trimmingCharacters(in: .whitespacesAndNewlines)
                let outcome = try await coordinator.completeActivation(key: key)
                verifyOutcome = outcome
                AnalyticsManager.shared.log(.licenseVerifySucceeded(outcome: Self.analyticsOutcomeName(outcome)))
            } catch {
                errorMessage = error.localizedDescription
                AnalyticsManager.shared.log(.licenseVerifyFailed(reason: Self.analyticsFailureReason(error)))
            }
        }
    }

    func createKey() {
        guard canCreateKey else { return }

        Task {
            isLoading = true
            errorMessage = nil
            verifyOutcome = nil

            defer { isLoading = false }

            AnalyticsManager.shared.log(.trialSignupAttempted)
            do {
                let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
                let outcome = try await coordinator.generateKeyAndActivate(
                    email: cleanEmail,
                    password: password
                )
                verifyOutcome = outcome
                AnalyticsManager.shared.log(.trialSignupSucceeded)
            } catch {
                errorMessage = error.localizedDescription
                AnalyticsManager.shared.log(.trialSignupFailed(reason: Self.analyticsFailureReason(error)))
            }
        }
    }

    func completeShiftAndRetryVerify(key: String) {
        Task {
            isLoading = true
            errorMessage = nil
            verifyOutcome = nil

            defer { isLoading = false }

            do {
                verifyOutcome = try await coordinator.completeActivation(key: key)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func forgotPasswordTapped() {
        showRecoverAccountSheet = true
        AnalyticsManager.shared.log(.forgotPasswordTapped)
    }

    // MARK: - Analytics helpers
    private static func analyticsOutcomeName(_ outcome: VerifyOutcome) -> String {
        switch outcome {
        case .success: return "success"
        case .shiftRequired: return "shift_required"
        case .trialExpired: return "trial_expired"
        case .licenseExpired: return "license_expired"
        }
    }
    
    private static func analyticsFailureReason(_ error: Error) -> String {
        switch error {
        case AppError.invalidInput: return "invalid_input"
        case AppError.notVerified: return "not_verified"
        case is APIError: return "api_error"
        default: return "other"
        }
    }
}
