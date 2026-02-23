//
//  ActivationRootView.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 22/02/2026.
//

import SwiftUI

private enum ActivationRootViewConstants {
    static let mainVStackSpacing: CGFloat = 14.0
    static let cardVStackSpacing: CGFloat = 16.0
    static let titleSubtitleVStackSpacing: CGFloat = 6.0
}

struct ActivationRootView: View {
    @Environment(\.designSystem) private var designSystem
    @Environment(\.appTheme) private var theme

    @StateObject private var viewModel = ActivationViewModel()
    private typealias Constants = ActivationRootViewConstants

    var body: some View {
        VStack(spacing: Constants.mainVStackSpacing) {
            header

            CardContainer {
                VStack(spacing: Constants.cardVStackSpacing) {
                    segmented

                    BrowserJetDivider()

                    content

                    if let msg = viewModel.errorMessage {
                        Text(msg)
                            .foregroundStyle(theme.danger)
                            .font(designSystem.typography.textBody1.font)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    submitButton

                    forgotPassword
                }
            }
        }
        .padding()
        .background(AppBackgroundStyle.browserJetGradient.makeView())
        .loadingOverlay(isLoading: viewModel.isLoading)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Constants.titleSubtitleVStackSpacing) {
            Text("Welcome to Browser Jet")
                .foregroundStyle(theme.textPrimary)
                .font(designSystem.typography.title1.font)

            Text("Activate your license to continue")
                .foregroundStyle(theme.textFieldSecondary)
                .font(designSystem.typography.textBody1.font)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var segmented: some View {
        BrowserJetSegmentedPicker(
            options: ActivationViewModel.Mode.allCases,
            selection: $viewModel.mode,
            isDisabled: false,
            label: { $0.rawValue }
        )
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.mode {
        case .activate:
            BrowserJetTextField(
                type: .activationField,
                title: "Enter Your Key",
                text: $viewModel.licenseKey,
                placeholder: "XXXXXXXXXXXX",
                rule: .licenseKey,
                validationState: $viewModel.licenseKeyValidation
            )

        case .register:
            VStack(spacing: 14) {
                BrowserJetTextField(
                    type: .activationField,
                    title: "Email Address",
                    text: $viewModel.email,
                    placeholder: "you@example.com",
                    rule: .email.message("Enter a valid email"),
                    validationState: $viewModel.emailValidation
                )

                BrowserJetTextField(
                    type: .activationField,
                    title: "Password",
                    text: $viewModel.password,
                    placeholder: "Enter password",
                    isSecure: true,
                    rule: .password,
                    validationState: $viewModel.passwordValidation
                )
            }
        }
    }

    private var submitButton: some View {
        BrowserJetAppButton(
            title: viewModel.mode.buttonTitle,
            type: .primaryLarge,
            height: 48,
            isDisabled: !viewModel.canSubmit
        ) {
            viewModel.submit()
        }
    }

    private var forgotPassword: some View {
        Button {
            viewModel.forgotPasswordTapped()
        } label: {
            Text("Forgot password?")
                .underline()
                .foregroundStyle(theme.accent)
                .font(designSystem.typography.textBody1.font)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.top, 2)
    }
}

#Preview("ActivationRootView") {
    ActivationRootView()
        .environment(\.appTheme, BrowserJetLightTheme())
        .environment(\.designSystem, DesignSystem())
        .frame(width: 520, height: 640)
}
