//
//  ActivationViewModel.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 22/02/2026.
//

import SwiftUI

@MainActor
final class ActivationViewModel: ObservableObject {

    enum Mode: String, CaseIterable, Hashable {
        case activate = "Use Key"
        case register = "Register"
        
        var buttonTitle: String {
            switch self {
            case .activate:
                return "Verify"
            case .register:
                return "Create Key"
            }
        }
    }

    // MARK: - Dependencies

    private let licenseService: LicenseService

    init(licenseService: LicenseService = LicenseService()) {
        self.licenseService = licenseService
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

    // MARK: - Submit Gate

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
            defer { isLoading = false }

            do {
                switch mode {
                case .activate:
                    let result = try await licenseService.verifyKey(licenseKey)
                    // handle result
                case .register:
                    let key = try await licenseService.generateKey(email: email, password: password)
                    // handle key
                }
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
