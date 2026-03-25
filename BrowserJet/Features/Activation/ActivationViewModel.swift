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

    // MARK: - Dependencies

    private let coordinator: LicenseActivationCoordinator

    init(coordinator: LicenseActivationCoordinator = LicenseActivationCoordinator()) {
        self.coordinator = coordinator
    }

    // MARK: - State

    @Published var mode: Mode = .activate

    @Published var licenseKey: String = ""

    @Published var email: String = ""
    @Published var password: String = ""

    @Published var licenseKeyValidation: RegexValidationState = .none
    @Published var emailValidation: RegexValidationState = .none
    @Published var passwordValidation: RegexValidationState = .none

    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

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
                    verifyOutcome = try await coordinator.completeActivation(key: licenseKey)
                case .register:
                    verifyOutcome = try await coordinator.generateKeyAndActivate(email: email, password: password)
                }
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
        // TODO: open URL or in-app flow
        print("🔗 Forgot password tapped")
    }
}
