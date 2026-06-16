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

            do {
                let key = licenseKey.trimmingCharacters(in: .whitespacesAndNewlines)
                verifyOutcome = try await coordinator.completeActivation(key: key)
            } catch {
                errorMessage = error.localizedDescription
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

            do {
                let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
                verifyOutcome = try await coordinator.generateKeyAndActivate(
                    email: cleanEmail,
                    password: password
                )
            } catch {
                errorMessage = error.localizedDescription
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
    }
}
