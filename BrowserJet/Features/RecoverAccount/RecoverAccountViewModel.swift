//
//  RecoverAccountViewModel.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 26/03/2026.
//

import Foundation

@MainActor
final class RecoverAccountViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var emailValidation: RegexValidationState = .none
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let licenseService: LicenseService
    
    init(licenseService: LicenseService = LicenseService()) {
        self.licenseService = licenseService
    }
    
    var canContinue: Bool {
        emailValidation == .valid
    }
    
    func submit() async -> Bool {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard ValidationRule.email.evaluate(trimmed) == .valid else { return false }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await licenseService.requestPasswordReset(email: trimmed)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
