//
//  LauncherView.swift
//  browserjet-wkwebview
//
//  Created by Moiz Ul Hasan on 10/02/2026.
//

import SwiftUI

// MARK: - Constants
private enum LauncherViewConstants {
    // Layout
    static let mainStackSpacing: CGFloat = 14.0
    static let launchButtonTopPadding: CGFloat = 10.0

    // Cards
    static let cardInterItemSpacing: CGFloat = 20.0

    // Buttons
    static let launchButtonHeight: CGFloat = 48.0

    // Pickers
    static let noOfTabsPickerWidth: CGFloat = 50.0
    static let vpnPickerWidth: CGFloat = 70.0
    static let regionPickerWidth: CGFloat = 50.0
}

struct LauncherView: View {
    @Environment(\.designSystem)
    private var designSystem

    @Environment(\.appTheme)
    private var theme

    private let config: AppConfiguration
    @StateObject private var viewModel: LauncherViewModel
    @ObservedObject private var premiumRepository = PremiumProxyRepository.shared
    @ObservedObject private var accountStore = LicenseAccountStore.shared
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var sessionManager: SessionManager
    
    private var presets: [LauncherTabPreset] {
        config.launcherTabPresets.filter { $0.rawValue <= config.maxBrowserTabs }
    }
    private typealias Constants = LauncherViewConstants

    init(appConfiguration: AppConfiguration) {
            self.config = appConfiguration
            _viewModel = StateObject(
                wrappedValue: LauncherViewModel(
                    defaultSearchAddress: appConfiguration.defaultSearchAddress,
                    appConfiguration: appConfiguration
                )
            )
        }

    var body: some View {
        VStack(spacing: Constants.mainStackSpacing) {
            userNameLogo
            searchBarCard
            vpnCard
            launchButton
                .padding(.top, Constants.launchButtonTopPadding)
        }
        .padding()
        .background(AppBackgroundStyle.browserJetGradient.makeView())
        .onAppear {
            viewModel.onAppear()
            // Initialize address only if empty
            if viewModel.settings.address.isEmpty {
                viewModel.updateAddress(config.defaultSearchAddress)
            }
        }
        .onChange(of: premiumRepository.hasPremiumProxies) { _, hasProxies in
            if hasProxies {
                viewModel.clearPremiumProxyUnavailableMessage()
            }
        }
        .onChange(of: premiumRepository.isLoading) { _, isLoading in
            if isLoading {
                viewModel.clearPremiumProxyUnavailableMessage()
            }
        }
    }

    private func getLabel(_ text: String) -> some View {
        Text(text)
            .foregroundStyle(theme.textPrimary)
            .font(designSystem.typography.textBody1.font)
    }

    private var launchButton: some View {
        BrowserJetAppButton(
            title: "Launch",
            type: .primaryLarge,
            height: Constants.launchButtonHeight,
            isDisabled: !viewModel.isLaunchAllowed(),
            action: showBrowser
        )
    }

    private func showBrowser() {
        let request = viewModel.settings.makeLaunchRequest(appConfiguration: config)
        WindowManager.shared.showBrowser(
            request: request,
            themeManager: themeManager,
            sessionManager: sessionManager,
            appConfiguration: config
        )
    }
}

// MARK: - Top View
private extension LauncherView {
    private var userNameLogo: some View {
        HStack {
            username
            Spacer()
            logoDescription
        }
    }

    private var username: some View {
        Text("Welcome \(accountStore.username)")
            .foregroundStyle(theme.textPrimary)
            .font(designSystem.typography.title1.font)
    }

    private var logoDescription: some View {
        Image(.icLogoDescription)
    }
}

// MARK: - Cards
private extension LauncherView {
    // Upper card
    private var addressField: some View {
        LauncherSearchField(text: Binding(
            get: { viewModel.settings.address },
            set: { viewModel.updateAddress($0) }
        ))
    }

    private var searchBarCard: some View {
        CardContainer {
            VStack(spacing: Constants.cardInterItemSpacing) {
                addressField
                numberOfTabs
            }
        }
    }

    private var numberOfTabs: some View {
        HStack {
            getLabel("No. of Tabs")
            Spacer()
            BrowserJetMenuPicker(
                options: presets,
                selection: Binding(
                    get: { viewModel.settings.numberOfTabs },
                    set: { viewModel.updateNumberOfTabs($0) }
                ),
                isDisabled: false,
                width: Constants.noOfTabsPickerWidth
            ) { $0.rawValue.toString }
        }
    }

    // Bottom card
    private var vpnCard: some View {
        CardContainer {
            VStack(spacing: Constants.cardInterItemSpacing) {
                HStack {
                    premiumProxyToggle
                    Spacer()
                    manageMyProxyButton
                }
                premiumStatusFootnotes
                BrowserJetDivider()
                HStack {
                    getLabel("VPN Status")
                    Spacer()
                    vpnToggle
                }
                selectVPNSection
                selectionRegion
            }
        }
    }

    @ViewBuilder
    private var premiumStatusFootnotes: some View {
        if premiumRepository.isLoading {
            HStack(alignment: .center, spacing: 8) {
                ProgressView()
                    .controlSize(.small)
                Text("Loading premium proxies…")
                    .foregroundStyle(theme.textFieldSecondary)
                    .font(designSystem.typography.textBody1.font)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else if let message = viewModel.premiumProxyUnavailableMessage {
            Text(message)
                .foregroundStyle(theme.textFieldSecondary)
                .font(designSystem.typography.textBody1.font)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var premiumProxyToggle: some View {
        HStack {
            GlassPillToggle(
                isOn: Binding(
                    get: { viewModel.settings.isPremiumProxyEnabled },
                    set: { viewModel.togglePremiumProxy($0) }
                ),
                isDisabled: premiumToggleDisabled
            )
            getLabel("Premium Proxy")
        }
    }

    /// Disabled while VPN is off or GPP is still loading. If the list is empty after load, the user can tap ON to see “no premium proxies” messaging.
    private var premiumToggleDisabled: Bool {
        if !viewModel.settings.isVPNEnabled || viewModel.availableVPNs.isEmpty { return true }
        if viewModel.settings.isPremiumProxyEnabled { return false }
        return premiumRepository.isLoading
    }

    private var manageMyProxyButton: some View {
        Button {
            viewModel.didTapManageMyProxy()
        } label: {
            HStack {
                Image(systemName: "gearshape")
                    .font(.title3)
                    .foregroundStyle(theme.accent)
                getLabel("Manage My Proxy")
            }
        }
        .buttonStyle(.plain)
    }

    private var vpnToggle: some View {
        GlassPillToggle(
            isOn: Binding(
                get: { viewModel.settings.isVPNEnabled },
                set: { viewModel.toggleVPN($0) }
            ),
            isDisabled: viewModel.availableVPNs.isEmpty
        )
    }

    private var selectVPNSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            selectVPNRow
            if viewModel.isTrialUser {
                Text(LauncherMessages.trialPaidVpnFootnote)
                    .foregroundStyle(theme.textFieldSecondary)
                    .font(designSystem.typography.textBody1.font)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @ViewBuilder
    private var selectVPNRow: some View {
        if viewModel.availableVPNs.isEmpty {
            HStack {
                getLabel("Select VPN")
                Spacer()
                Text("—")
                    .foregroundStyle(theme.textFieldSecondary)
                    .font(designSystem.typography.textBody1.font)
            }
        } else {
            HStack {
                getLabel("Select VPN")
                Spacer()
                BrowserJetMenuPicker(
                    options: viewModel.availableVPNs,
                    selection: vpnPickerSelectionBinding,
                    isDisabled: !viewModel.settings.areVPNControlsEnabled || viewModel.availableVPNs.isEmpty,
                    width: Constants.vpnPickerWidth
                ) { VPNType.displayName(for: $0, in: config.vpnConfigurations) }
            }
        }
    }

    private var vpnPickerSelectionBinding: Binding<VPNType> {
        Binding(
            get: {
                let selected = viewModel.settings.selectedVPN
                if let selected, viewModel.availableVPNs.contains(selected) {
                    return selected
                }
                return viewModel.availableVPNs.first!
            },
            set: { viewModel.updateSelectedVPN($0) }
        )
    }

    private var selectionRegion: some View {
        HStack {
            getLabel("Select Region")
            Spacer()
            BrowserJetMenuPicker(
                options: viewModel.regionPickerOptions,
                selection: Binding(
                    get: { viewModel.settings.selectedRegion ?? .uk },
                    set: { viewModel.updateSelectedRegion($0) }
                ),
                isDisabled: !viewModel.settings.areRegionControlsEnabled,
                width: Constants.regionPickerWidth
            ) { $0.rawValue }
        }
    }
}

#Preview {
    LauncherView(appConfiguration: .development)
}
