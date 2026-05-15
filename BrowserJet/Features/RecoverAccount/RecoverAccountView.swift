//
//  RecoverAccountView.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 26/03/2026.
//

import SwiftUI

struct RecoverAccountView: View {
    @Environment(\.designSystem)
    private var designSystem
    @Environment(\.appTheme)
    private var theme
    @Environment(\.dismiss)
    private var dismiss

    @StateObject private var viewModel = RecoverAccountViewModel()
    @State private var didSucceed = false

    var body: some View {
        Group {
            if didSucceed {
                successContent
            } else {
                formContent
            }
        }
        .padding(24)
        .frame(minWidth: 400, minHeight: didSucceed ? 420 : 520)
        .background(Color.clear)
    }

    private var formContent: some View {
        InfoAlertChrome(minWidth: 360, maxWidth: 440) {
            VStack(alignment: .leading, spacing: DesignMetrics.sectionSpacing) {
                Image(.icLogoDescription)
                    .frame(maxWidth: .infinity)

                Text(ActivationMessages.AccountRecovery.headline)
                    .font(designSystem.typography.title1.font)
                    .foregroundStyle(theme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                BrowserJetTextField(
                    type: .activationField,
                    title: ActivationMessages.emailAddressTitle,
                    text: $viewModel.email,
                    placeholder: ActivationMessages.emailPlaceholder,
                    rule: .email.message(ActivationMessages.emailValidationMessage),
                    validationState: $viewModel.emailValidation
                )

                Text(ActivationMessages.AccountRecovery.body)
                    .font(designSystem.typography.textBody1.font)
                    .foregroundStyle(theme.textFieldSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let msg = viewModel.errorMessage {
                    Text(msg)
                        .font(designSystem.typography.textBody1.font)
                        .foregroundStyle(theme.danger)
                        .fixedSize(horizontal: false, vertical: true)
                }

                BrowserJetAppButton(
                    title: ActivationMessages.AccountRecovery.continueButton,
                    type: .primaryLarge,
                    height: 48,
                    isDisabled: !viewModel.canContinue || viewModel.isLoading
                ) {
                    Task {
                        let didSubmitSuccessfully = await viewModel.submit()
                        if didSubmitSuccessfully { didSucceed = true }
                    }
                }

                dismissSheetButton(locksWhileLoading: true)
            }
        }
        .loadingOverlay(isLoading: viewModel.isLoading)
    }

    private var successContent: some View {
        InfoAlertChrome(minWidth: 360, maxWidth: 440) {
            VStack(spacing: DesignMetrics.sectionSpacing) {
                Image(.icLogoDescription)

                Text(ActivationMessages.AccountRecoverySuccess.title)
                    .font(designSystem.typography.title1.font)
                    .foregroundStyle(theme.textPrimary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)

                Text(ActivationMessages.AccountRecoverySuccess.message)
                    .font(designSystem.typography.textBody1.font)
                    .foregroundStyle(theme.textFieldSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)

                VStack(spacing: DesignMetrics.rowSpacing) {
                    BrowserJetAppButton(
                        title: ActivationMessages.AccountRecoverySuccess.openDashboard,
                        type: .primaryLarge,
                        height: 48,
                        isDisabled: false
                    ) {
                        AppLogger.info("Open dashboard")
                    }

                    dismissSheetButton(locksWhileLoading: false)
                }
            }
        }
    }

    /// Secondary dismiss — disabled during submit on the form step so the request isn’t abandoned mid-flight.
    private func dismissSheetButton(locksWhileLoading: Bool) -> some View {
        BrowserJetAppButton(
            title: ActivationMessages.AccountRecovery.dismissSheet,
            type: .secondaryLarge,
            height: 48,
            isDisabled: locksWhileLoading && viewModel.isLoading
        ) {
            dismiss()
        }
    }
}

#Preview("Recover account") {
    RecoverAccountView()
        .environment(\.appTheme, BrowserJetLightTheme())
        .environment(\.designSystem, DesignSystem())
}
