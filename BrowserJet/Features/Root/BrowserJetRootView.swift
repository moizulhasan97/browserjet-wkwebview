//
//  BrowserJetRootView.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 25/03/2026.
//

import SwiftUI

// MARK: - Window Root (theme bridge)
struct BrowserJetWindowRoot: View {
    @Environment(\.colorScheme)
    private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager
    @ObservedObject private var forceGate = ForceUpdateGate.shared

    var body: some View {
        Group {
            if forceGate.isBlocking {
                ForceUpdateBlockingOverlay(isDimmed: false)
            } else {
                BrowserJetRootView()
            }
        }
        .browserJetThemedRoot(themeManager: themeManager, colorScheme: colorScheme)
        .onAppear {
            guard forceGate.isBlocking else { return }
            WindowManager.shared.resizeActivationWindowForForceUpdateIfPresent()
        }
        .onPreferenceChange(ActivationMeasuredContentSizeKey.self) { size in
            guard forceGate.isBlocking, size.height > 0 else { return }
            WindowManager.shared.resizeActivationWindowForForceUpdateContent(size.height)
        }
        .onChange(of: forceGate.isBlocking) { _, isBlocking in
            guard isBlocking else { return }
            WindowManager.shared.resizeActivationWindowForForceUpdateIfPresent()
        }
    }
}

private enum AppEntryPhase {
    /// Full activation / registration UI.
    case activation
    /// Network verify of `StorageKeys.licenseKey` in progress.
    case verifyingStoredKey
    /// Verify RPC finished; showing shift / alerts. Distinct from `.verifyingStoredKey` so clearing
    /// `bootstrapVerifyOutcome` (e.g. trial → payment alert) does not fall back to the verifying spinner.
    case storedKeyPostVerify
}

struct BrowserJetRootView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var sessionManager: SessionManager
    @Environment(\.appConfiguration)
    private var appConfiguration: AppConfiguration
    @Environment(\.appTheme)
    private var theme
    @Environment(\.designSystem)
    private var designSystem
    @Environment(\.colorScheme)
    private var colorScheme

    private let coordinator = LicenseActivationCoordinator()
    private let keyValueStore: KeyValueStoring = UserDefaultsKeyValueStore()
    @State private var phase: AppEntryPhase = Self.initialPhaseFromStoredKey()
    @State private var storedKeyVerifyFailureMessage: String?
    @State private var bootstrapVerifyOutcome: VerifyOutcome?
    @State private var showBootstrapShiftSuccessAlert: Bool = false
    @State private var bootstrapPaymentAlert: PaymentAlertItem?

    var body: some View {
        Group {
            if phase == .activation {
                activationFullChrome
            } else {
                compactBootstrapChrome
                    .reportActivationContentSize()
            }
        }
        .onAppear { syncActivationWindowFrame() }
        .onChange(of: phase) { _, _ in syncActivationWindowFrame() }
        .onChange(of: showBootstrapShiftSuccessAlert) { _, _ in syncActivationWindowFrame() }
        .onChange(of: bootstrapPaymentAlert?.id) { _, _ in syncActivationWindowFrame() }
        .onChange(of: storedKeyVerifyFailureMessage) { _, _ in
            guard phase == .activation else { return }
            syncActivationWindowFrame()
        }
        .onPreferenceChange(ActivationMeasuredContentSizeKey.self) { size in
            applyActivationContentSize(size)
        }
        .task {
            await runInitialEntry()
        }
        .onChange(of: bootstrapVerifyOutcome) { _, outcome in
            handleBootstrapVerifyOutcome(outcome)
        }
    }

    private var activationFullChrome: some View {
        VStack(spacing: 0) {
            if let msg = storedKeyVerifyFailureMessage {
                Text(msg)
                    .foregroundStyle(theme.danger)
                    .font(designSystem.typography.textBody1.font)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(theme.danger.opacity(0.12))
            }
            ActivationRootView()
        }
        .frame(width: ActivationWindowMetrics.contentWidth)
        .fixedSize(horizontal: false, vertical: true)
        .reportActivationContentSize()
    }

    @ViewBuilder private var compactBootstrapChrome: some View {
        if phase == .verifyingStoredKey {
            InfoAlertProgressView()
        } else if case let .shiftRequired(shiftKey, shiftEmail) = bootstrapVerifyOutcome {
            InfoAlertChrome(minWidth: 420, maxWidth: 480) {
                VStack(alignment: .leading, spacing: DesignMetrics.sectionSpacing) {
                    ShiftLicenseView(
                        key: shiftKey,
                        email: shiftEmail
                    ) {
                        bootstrapVerifyOutcome = nil
                        showBootstrapShiftSuccessAlert = true
                    }
                    .id("\(shiftKey)|\(shiftEmail)")
                }
            }
        } else if showBootstrapShiftSuccessAlert {
            InfoAlertView(
                title: ActivationMessages.ShiftSuccess.title,
                message: ActivationMessages.ShiftSuccess.message,
                buttonTitle: ActivationMessages.okButtonTitle
            ) {
                showBootstrapShiftSuccessAlert = false
                Task { await verifyPersistedLicenseKey(emptyKeyUserMessage: "License key missing after shift.") }
            }
        } else if let alert = bootstrapPaymentAlert {
            InfoAlertView(
                title: alert.title,
                message: alert.message,
                buttonTitle: ActivationMessages.okButtonTitle
            ) {
                bootstrapPaymentAlert = nil
                WindowManager.shared.showBrowserForTrialExpired(
                    paymentURL: alert.url,
                    themeManager: themeManager,
                    sessionManager: sessionManager,
                    appConfiguration: appConfiguration
                )
            }
        } else {
            InfoAlertProgressView(message: ActivationMessages.bootstrapLoadingProgress)
        }
    }

    private var activationWindowLayout: WindowManager.ActivationLayout {
        if phase == .activation {
            return .fullForm
        }
        if case .shiftRequired = bootstrapVerifyOutcome {
            return .shiftLicense
        }
        if showBootstrapShiftSuccessAlert {
            return .infoAlert
        }
        if bootstrapPaymentAlert != nil {
            return .infoAlert
        }
        return .progressOnly
    }

    private func syncActivationWindowFrame() {
        WindowManager.shared.resizeActivationWindowToFit(activationWindowLayout)
    }

    private func applyActivationContentSize(_ size: CGSize) {
        guard size.height > 0 else { return }
        if phase == .activation {
            WindowManager.shared.resizeActivationFullFormToContentHeight(size.height)
        } else {
            WindowManager.shared.resizeActivationWindowForCompactContent(size, layout: activationWindowLayout)
        }
    }

    private func handleBootstrapVerifyOutcome(_ outcome: VerifyOutcome?) {
        guard let outcome else {
            syncActivationWindowFrame()
            return
        }
        switch outcome {
        case .success:
            bootstrapVerifyOutcome = nil
            WindowManager.shared.dismissActivationAndShowLauncher(
                themeManager: themeManager,
                sessionManager: sessionManager,
                appConfiguration: appConfiguration
            )
        case .trialExpired(let url):
            bootstrapVerifyOutcome = nil
            bootstrapPaymentAlert = PaymentAlertItem(
                title: ActivationMessages.TrialExpired.title,
                message: ActivationMessages.TrialExpired.message,
                url: url
            )
        case .licenseExpired(let url):
            bootstrapVerifyOutcome = nil
            bootstrapPaymentAlert = PaymentAlertItem(
                title: ActivationMessages.LicenseExpired.title,
                message: ActivationMessages.LicenseExpired.message,
                url: url
            )
        case .shiftRequired:
            break
        }
        syncActivationWindowFrame()
    }

    private static func initialPhaseFromStoredKey() -> AppEntryPhase {
        guard let raw = UserDefaults.standard.object(forKey: StorageKeys.licenseKey) as? String else {
            return .activation
        }
        let key = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return key.isEmpty ? .activation : .verifyingStoredKey
    }

    @MainActor
    private func runInitialEntry() async {
        await verifyPersistedLicenseKey(emptyKeyUserMessage: nil)
    }

    @MainActor
    private func verifyPersistedLicenseKey(emptyKeyUserMessage: String?) async {
        let raw = keyValueStore.object(forKey: StorageKeys.licenseKey) as? String ?? ""
        let key = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else {
            if let emptyKeyUserMessage {
                storedKeyVerifyFailureMessage = emptyKeyUserMessage
            }
            phase = .activation
            return
        }

        phase = .verifyingStoredKey
        do {
            let outcome = try await coordinator.completeActivation(key: key)
            phase = .storedKeyPostVerify
            bootstrapVerifyOutcome = outcome
        } catch {
            storedKeyVerifyFailureMessage = error.localizedDescription
            phase = .activation
        }
    }
}
