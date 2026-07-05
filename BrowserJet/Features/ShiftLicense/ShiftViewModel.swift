//
//  ShiftViewModel.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 02/03/2026.
//

import SwiftUI

@MainActor
final class ShiftViewModel: ObservableObject {
    @Published private(set) var pcName: String?
    @Published var isLoading = false
    @Published var errorMessage: String?
    private let key: String
    private let email: String
    private let licenseService: LicenseService
    private var onShiftSucceeded: (() -> Void)?

    init(
        licenseService: LicenseService = LicenseService(),
        key: String,
        email: String,
        onShiftSucceeded: (() -> Void)? = nil
    ) {
        self.licenseService = licenseService
        self.key = key
        self.email = email
        self.onShiftSucceeded = onShiftSucceeded
    }

    func onAppear() {
        fetchPCName()
    }

    private func fetchPCName() {
        Task {
            isLoading = true
            errorMessage = nil
            defer { isLoading = false }
            do {
                let name = try await licenseService.getPCDetails(key: key)
                pcName = name
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func didTapShift() {
        guard let oldPcName = pcName, !oldPcName.isEmpty else {
            errorMessage = "Device name is missing."
            return
        }
        AnalyticsManager.shared.log(.shiftLicenseTapped)
        Task {
            isLoading = true
            errorMessage = nil
            defer { isLoading = false }
            do {
                try await licenseService.shiftKey(from: oldPcName, key: key, email: email)
                onShiftSucceeded?()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
