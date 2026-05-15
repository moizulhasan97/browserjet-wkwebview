//
//  ChangeLicenseKeyViewModel.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 06/05/2026.
//

import Foundation

@MainActor
final class ChangeLicenseKeyViewModel: ObservableObject {
    @Published var licenseKey: String = ""
    @Published var licenseKeyValidation: RegexValidationState = .none
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var didSucceed: Bool = false
    @Published var sameKeyMessage: String?

    private let keyValueStore: KeyValueStoring
    private let coordinator: LicenseActivationCoordinator

    init(
        coordinator: LicenseActivationCoordinator = LicenseActivationCoordinator(),
        keyValueStore: KeyValueStoring = UserDefaultsKeyValueStore()
    ) {
        self.coordinator = coordinator
        self.keyValueStore = keyValueStore
    }

    func reset() {
        licenseKey = ""
        licenseKeyValidation = .none
        isLoading = false
        errorMessage = nil
        sameKeyMessage = nil
        didSucceed = false
    }

    func submit() {
        onLicenseKeyChanged()

        guard canSubmit else {
            if isSameAsCurrentKey {
                errorMessage = nil
            }
            return
        }

        let key = licenseKey.trimmingCharacters(in: .whitespacesAndNewlines)

        Task {
            isLoading = true
            errorMessage = nil
            didSucceed = false
            defer { isLoading = false }

            do {
                try await coordinator.changeLicenseKey(key: key)
                didSucceed = true
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private var normalizedInputKey: String {
        licenseKey.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }

    private var normalizedStoredKey: String {
        let raw = keyValueStore.object(forKey: StorageKeys.licenseKey) as? String ?? ""
        return raw.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }

    private var isSameAsCurrentKey: Bool {
        !normalizedInputKey.isEmpty && normalizedInputKey == normalizedStoredKey
    }

    var canSubmit: Bool {
        licenseKeyValidation == .valid && !isLoading && !isSameAsCurrentKey
    }

    func onLicenseKeyChanged() {
        if isSameAsCurrentKey {
            sameKeyMessage = "You entered your current key. Please enter a different key."
        } else {
            sameKeyMessage = nil
        }
    }
}
