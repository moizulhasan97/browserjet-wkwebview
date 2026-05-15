//
//  ChangeLicenseKeyView.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 06/05/2026.
//

import SwiftUI

struct ChangeLicenseKeyView: View {
    @Environment(\.designSystem)
    private var designSystem
    @Environment(\.appTheme)
    private var theme
    @Environment(\.dismiss)
    private var dismiss

    @ObservedObject var viewModel: ChangeLicenseKeyViewModel

    var body: some View {
        InfoAlertChrome(minWidth: 420, maxWidth: 500) {
            VStack(alignment: .leading, spacing: DesignMetrics.sectionSpacing) {
                header
                keyField
                actions
                errorText
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: DesignMetrics.rowSpacing) {
            Text("Change License Key")
                .font(designSystem.typography.title1.font)
                .foregroundStyle(theme.textPrimary)

            Text("Enter your new BrowserJet license key to replace the current key on this device.")
                .font(designSystem.typography.textBody1.font)
                .foregroundStyle(theme.textFieldSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var keyField: some View {
        VStack(alignment: .leading, spacing: 6) {
            BrowserJetTextField(
                type: .activationField,
                title: "New Key",
                text: $viewModel.licenseKey,
                placeholder: "XXXXXXXXXXXX",
                rule: .licenseKey,
                validationState: $viewModel.licenseKeyValidation
            )
            .onSubmit {
                viewModel.submit()
            }
            .onChange(of: viewModel.licenseKey) { _, _ in
                viewModel.onLicenseKeyChanged()
            }

            if let sameKeyMessage = viewModel.sameKeyMessage {
                Text(sameKeyMessage)
                    .font(designSystem.typography.textBody2.font)
                    .foregroundStyle(theme.danger)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var actions: some View {
        HStack(spacing: 12) {
            BrowserJetAppButton(
                title: "Cancel",
                type: .secondaryLarge,
                height: 44,
                isDisabled: false
            ) {
                dismiss()
            }
            .keyboardShortcut(.cancelAction)

            BrowserJetAppButton(
                title: viewModel.isLoading ? "Please wait..." : "Change Key",
                type: .primaryLarge,
                height: 44,
                isDisabled: !viewModel.canSubmit
            ) {
                viewModel.submit()
            }
            .keyboardShortcut(.defaultAction)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    @ViewBuilder private var errorText: some View {
        if let message = viewModel.errorMessage {
            Text(message)
                .font(designSystem.typography.textBody2.font)
                .foregroundStyle(theme.danger)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
