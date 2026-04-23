//
//  ActivationRootView.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 22/02/2026.
//

import SwiftUI

// MARK: - Window Root (theme bridge)
struct ActivationWindowRoot: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        ActivationRootView()
            .environment(\.appTheme, themeManager.theme(for: colorScheme))
    }
}

// MARK: - Constants
private enum ActivationRootViewConstants {
    static let mainVStackSpacing: CGFloat = 14.0
    static let cardVStackSpacing: CGFloat = 16.0
    static let titleSubtitleVStackSpacing: CGFloat = 6.0
}

struct ActivationRootView: View {
    @Environment(\.designSystem) private var designSystem
    @Environment(\.appTheme) private var theme
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var sessionManager: SessionManager
    @Environment(\.appConfiguration) private var appConfiguration: AppConfiguration
    
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
        .onChange(of: viewModel.verifyOutcome) { _, outcome in
            if case .success = outcome {
                viewModel.verifyOutcome = nil
                showVerificationSuccessAlert = true
            }
            if case .trialExpired(let url) = outcome {
                viewModel.verifyOutcome = nil
                paymentAlert = PaymentAlertItem(
                    title: ActivationMessages.TrialExpired.title,
                    message: ActivationMessages.TrialExpired.message,
                    url: url
                )
            }
            if case .licenseExpired(let url) = outcome {
                viewModel.verifyOutcome = nil
                paymentAlert = PaymentAlertItem(
                    title: ActivationMessages.LicenseExpired.title,
                    message: ActivationMessages.LicenseExpired.message,
                    url: url
                )
            }
        }
        .sheet(isPresented: Binding(
            get: {
                if case .shiftRequired = viewModel.verifyOutcome { return true }
                return false
            },
            set: { if !$0 { viewModel.verifyOutcome = nil } }
        )) {
            if case .shiftRequired(let key, let email) = viewModel.verifyOutcome {
                ShiftLicenseView(
                    key: key,
                    email: email,
                    onShiftSucceeded: {
                        viewModel.verifyOutcome = nil
                        showShiftSuccessAlert = true
                    }
                )
                .id("\(key)|\(email)")
            }
        }
        .sheet(isPresented: $showShiftSuccessAlert) {
            InfoAlertView(
                title: ActivationMessages.ShiftSuccess.title,
                message: ActivationMessages.ShiftSuccess.message,
                buttonTitle: ActivationMessages.okButtonTitle,
                onDismiss: {
                    showShiftSuccessAlert = false
                    let raw = keyValueStore.object(forKey: StorageKeys.licenseKey) as? String ?? ""
                    let key = raw.trimmingCharacters(in: .whitespacesAndNewlines)
                    viewModel.completeShiftAndRetryVerify(key: key)
                }
            )
        }
        .sheet(isPresented: $showVerificationSuccessAlert) {
            InfoAlertView(
                title: ActivationMessages.VerificationSuccess.title,
                message: ActivationMessages.VerificationSuccess.message,
                buttonTitle: ActivationMessages.okButtonTitle,
                onDismiss: {
                    showVerificationSuccessAlert = false
                    WindowManager.shared.dismissActivationAndShowLauncher(
                        themeManager: themeManager,
                        sessionManager: sessionManager,
                        appConfiguration: appConfiguration
                    )
                }
            )
        }
        .sheet(item: $paymentAlert) { alert in
            InfoAlertView(
                title: alert.title,
                message: alert.message,
                buttonTitle: ActivationMessages.okButtonTitle,
                onDismiss: {
                    paymentAlert = nil
                    WindowManager.shared.showBrowserForTrialExpired(
                        paymentURL: alert.url,
                        themeManager: themeManager,
                        sessionManager: sessionManager,
                        appConfiguration: appConfiguration
                    )
                }
            )
        }
        .sheet(isPresented: $viewModel.showRecoverAccountSheet, onDismiss: {
            viewModel.showRecoverAccountSheet = false
        }) {
            RecoverAccountView()
                .environment(\.appTheme, theme)
                .environment(\.designSystem, designSystem)
        }
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: Constants.titleSubtitleVStackSpacing) {
            Text(ActivationMessages.welcomeTitle)
                .foregroundStyle(theme.textPrimary)
                .font(designSystem.typography.title1.font)
            
            Text(ActivationMessages.activateSubtitle)
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
            label: { $0.displayLabel }
        )
    }
    
    @ViewBuilder
    private var content: some View {
        switch viewModel.mode {
        case .activate:
            BrowserJetTextField(
                type: .activationField,
                title: ActivationMessages.enterYourKeyTitle,
                text: $viewModel.licenseKey,
                placeholder: ActivationMessages.licenseKeyPlaceholder,
                rule: .licenseKey,
                validationState: $viewModel.licenseKeyValidation
            )
            
        case .register:
            VStack(spacing: 14) {
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
            Text(ActivationMessages.recoverAccountLink)
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
        .environmentObject(ThemeManager())
        .environmentObject(SessionManager())
        .environment(\.appConfiguration, AppConfiguration.development)
        .frame(width: 520, height: 640)
}
