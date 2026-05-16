//
//  ActivationRootView.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 22/02/2026.
//

import SwiftUI

// MARK: - Root
struct ActivationWindowRoot: View {
    @Environment(\.colorScheme)
    private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        ActivationRootView()
            .environment(\.appTheme, themeManager.theme(for: colorScheme))
    }
}

// MARK: - Constants
private enum ActivationRootViewConstants {
    static let mainVStackSpacing: CGFloat = 18.0
    static let cardVStackSpacing: CGFloat = 18.0
    static let titleSubtitleVStackSpacing: CGFloat = 8.0
    static let sectionSpacing: CGFloat = 14.0
    static let fieldSpacing: CGFloat = 14.0
    static let buttonHeight: CGFloat = 48.0
}

// MARK: - View

struct ActivationRootView: View {
    @Environment(\.designSystem)
    private var designSystem
    @Environment(\.appTheme)
    private var theme
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var sessionManager: SessionManager
    @Environment(\.appConfiguration)
    private var appConfiguration: AppConfiguration
    @Environment(\.colorScheme)
    private var colorScheme

    @StateObject private var viewModel = ActivationViewModel()

    private let keyValueStore: KeyValueStoring = UserDefaultsKeyValueStore()

    @State private var showShiftSuccessAlert: Bool = false
    @State private var showVerificationSuccessAlert: Bool = false
    @State private var paymentAlert: PaymentAlertItem?

    private typealias Constants = ActivationRootViewConstants

    var body: some View {
        VStack(spacing: Constants.mainVStackSpacing) {
            header

            CardContainer {
                VStack(spacing: Constants.cardVStackSpacing) {
                    activationSection

                    orDivider

                    registrationSection

                    recoverAccountButton

                    feedbackMessage
                }
            }
        }
        .padding()
        .background(
            AppBackgroundStyle
                .brandGradient(for: themeManager.resolvedColorScheme(for: colorScheme))
                .makeView()
        )
        .loadingOverlay(isLoading: viewModel.isLoading)
        .onChange(of: viewModel.verifyOutcome) { _, outcome in
            handleVerifyOutcome(outcome)
        }
        .sheet(isPresented: Binding(
            get: {
                if case .shiftRequired = viewModel.verifyOutcome { return true }
                return false
            },
            set: { if !$0 { viewModel.verifyOutcome = nil } }
        )) {
            if case let .shiftRequired(key, email) = viewModel.verifyOutcome {
                ShiftLicenseView(
                    key: key,
                    email: email
                ) {
                    viewModel.verifyOutcome = nil
                    showShiftSuccessAlert = true
                }
                .id("\(key)|\(email)")
            }
        }
        .sheet(isPresented: $showShiftSuccessAlert) {
            InfoAlertView(
                title: ActivationMessages.ShiftSuccess.title,
                message: ActivationMessages.ShiftSuccess.message,
                buttonTitle: ActivationMessages.okButtonTitle
            ) {
                showShiftSuccessAlert = false

                let raw = keyValueStore.object(forKey: StorageKeys.licenseKey) as? String ?? ""
                let key = raw.trimmingCharacters(in: .whitespacesAndNewlines)

                viewModel.completeShiftAndRetryVerify(key: key)
            }
        }
        .sheet(isPresented: $showVerificationSuccessAlert) {
            InfoAlertView(
                title: ActivationMessages.VerificationSuccess.title,
                message: ActivationMessages.VerificationSuccess.message,
                buttonTitle: ActivationMessages.okButtonTitle
            ) {
                showVerificationSuccessAlert = false

                WindowManager.shared.dismissActivationAndShowLauncher(
                    themeManager: themeManager,
                    sessionManager: sessionManager,
                    appConfiguration: appConfiguration
                )
            }
        }
        .sheet(item: $paymentAlert) { alert in
            InfoAlertView(
                title: alert.title,
                message: alert.message,
                buttonTitle: ActivationMessages.okButtonTitle
            ) {
                paymentAlert = nil

                WindowManager.shared.showBrowserForTrialExpired(
                    paymentURL: alert.url,
                    themeManager: themeManager,
                    sessionManager: sessionManager,
                    appConfiguration: appConfiguration
                )
            }
        }
        .sheet(
            isPresented: $viewModel.showRecoverAccountSheet,
            onDismiss: { viewModel.showRecoverAccountSheet = false },
            content: {
                RecoverAccountView()
                    .environment(\.appTheme, theme)
                    .environment(\.designSystem, designSystem)
            }
        )
    }
}

// MARK: - Subviews

private extension ActivationRootView {
    var header: some View {
        VStack(alignment: .leading, spacing: Constants.titleSubtitleVStackSpacing) {
            Text(ActivationMessages.welcomeTitle)
                .foregroundStyle(theme.textPrimary)
                .font(designSystem.typography.title1.font)

            Text("Activate your license or create a new key to continue")
                .foregroundStyle(theme.textFieldSecondary)
                .font(designSystem.typography.textBody1.font)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var activationSection: some View {
        VStack(alignment: .leading, spacing: Constants.sectionSpacing) {
            sectionHeader(
                title: "Already have a license key?",
                subtitle: "Enter your key below to activate Browser Jet."
            )

            BrowserJetTextField(
                type: .activationField,
                title: ActivationMessages.enterYourKeyTitle,
                text: $viewModel.licenseKey,
                placeholder: ActivationMessages.licenseKeyPlaceholder,
                rule: .licenseKey,
                validationState: $viewModel.licenseKeyValidation
            )

            BrowserJetAppButton(
                title: ActivationMessages.Mode.verifyButton,
                type: .primaryLarge,
                height: Constants.buttonHeight,
                isDisabled: !viewModel.canVerifyKey
            ) {
                viewModel.verifyKey()
            }
            .opacity(viewModel.canVerifyKey ? 1.0 : 0.7)
            .animation(.easeInOut(duration: 0.2), value: viewModel.canVerifyKey)
        }
    }

    var registrationSection: some View {
        VStack(alignment: .leading, spacing: Constants.sectionSpacing) {
            sectionHeader(
                title: "New user?",
                subtitle: "Create a key using your email and password."
            )

            VStack(spacing: Constants.fieldSpacing) {
                BrowserJetTextField(
                    type: .activationField,
                    title: ActivationMessages.emailAddressTitle,
                    text: $viewModel.email,
                    placeholder: ActivationMessages.emailPlaceholder,
                    rule: ValidationRule.email,
                    validationState: $viewModel.emailValidation
                )

                BrowserJetTextField(
                    type: .activationField,
                    title: ActivationMessages.passwordTitle,
                    text: $viewModel.password,
                    placeholder: ActivationMessages.passwordPlaceholder,
                    isSecure: true,
                    rule: ValidationRule.password,
                    validationState: $viewModel.passwordValidation
                )
            }

            BrowserJetAppButton(
                title: ActivationMessages.Mode.createKeyButton,
                type: .primaryLarge,
                height: Constants.buttonHeight,
                isDisabled: !viewModel.canCreateKey
            ) {
                viewModel.createKey()
            }
            .opacity(viewModel.canCreateKey ? 1.0 : 0.7)
            .animation(.easeInOut(duration: 0.2), value: viewModel.canCreateKey)
        }
    }

    var orDivider: some View {
        HStack(spacing: 12) {
            BrowserJetDivider()

            Text("OR")
                .foregroundStyle(theme.textFieldSecondary)
                .font(designSystem.typography.textBody2.font)

            BrowserJetDivider()
        }
    }

    func sectionHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .foregroundStyle(theme.textPrimary)
                .font(designSystem.typography.textBody1.font)

            Text(subtitle)
                .foregroundStyle(theme.textFieldSecondary)
                .font(designSystem.typography.textBody2.font)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var recoverAccountButton: some View {
        Button {
            viewModel.forgotPasswordTapped()
        } label: {
            Text(ActivationMessages.recoverAccountLink)
                .foregroundStyle(theme.accent)
                .font(designSystem.typography.textBody2.font)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.top, 2)
    }

    @ViewBuilder var feedbackMessage: some View {
        if let msg = viewModel.errorMessage {
            Text(msg)
                .foregroundStyle(theme.danger)
                .font(designSystem.typography.textBody2.font)
                .frame(maxWidth: .infinity, alignment: .leading)
                .transition(.opacity)
        }
    }
}

// MARK: - Actions

private extension ActivationRootView {
    func handleVerifyOutcome(_ outcome: VerifyOutcome?) {
        guard let outcome else { return }

        switch outcome {
        case .success:
            viewModel.verifyOutcome = nil
            showVerificationSuccessAlert = true

        case .shiftRequired:
            break

        case .trialExpired(let url):
            viewModel.verifyOutcome = nil
            paymentAlert = PaymentAlertItem(
                title: ActivationMessages.TrialExpired.title,
                message: ActivationMessages.TrialExpired.message,
                url: url
            )

        case .licenseExpired(let url):
            viewModel.verifyOutcome = nil
            paymentAlert = PaymentAlertItem(
                title: ActivationMessages.LicenseExpired.title,
                message: ActivationMessages.LicenseExpired.message,
                url: url
            )
        }
    }
}

#Preview("ActivationRootView") {
    ActivationRootView()
        .environment(\.appTheme, BrowserJetLightTheme())
        .environment(\.designSystem, DesignSystem())
        .environmentObject(ThemeManager())
        .environmentObject(SessionManager())
        .environment(\.appConfiguration, AppConfiguration.development)
        .frame(width: 520, height: 640)
}
