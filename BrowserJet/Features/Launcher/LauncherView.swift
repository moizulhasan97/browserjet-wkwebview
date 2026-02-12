//
//  LauncherView.swift
//  browserjet-wkwebview
//
//  Created by Moiz Ul Hasan on 10/02/2026.
//

import SwiftUI

// MARK: - Constants
fileprivate enum LauncherViewConstants {
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
    
    @Environment(\.designSystem) private var designSystem
    @Environment(\.appTheme) private var theme
    @Environment(\.appConfiguration) private var config
    @StateObject private var viewModel: LauncherViewModel
    
    private var presets: [LauncherTabPreset] {
        config.launcherTabPresets
    }
    private typealias K = LauncherViewConstants
    
    init() {
        _viewModel = StateObject(wrappedValue: LauncherViewModel(defaultSearchAddress: ""))
    }
    
    var body: some View {
        VStack (spacing: K.mainStackSpacing) {
            userNameLogo
            searchBarCard
            vpnCard
            launchButton
                .padding(.top, K.launchButtonTopPadding)
        }
        .padding()
        .background(AppBackgroundStyle.browserJetGradient.makeView())
        .onAppear {
            if viewModel.settings.address.isEmpty {
                viewModel.updateAddress(config.defaultSearchAddress)
            }
            viewModel.onAppear()
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
            height: K.launchButtonHeight,
            isDisabled: !viewModel.settings.isValid,
            action: viewModel.didTapLaunch
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
        Text("Welcome Gabriel")
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
            VStack (spacing: K.cardInterItemSpacing) {
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
                width: K.noOfTabsPickerWidth,
                label: { $0.rawValue.toString }
            )
        }
    }
    
    // Bottom card
    private var vpnCard: some View {
        CardContainer {
            VStack (spacing: K.cardInterItemSpacing) {
                HStack {
                    premiumProxyToggle
                    Spacer()
                    manageMyProxyButton
                }
                BrowserJetDivider()
                HStack {
                    getLabel("VPN Status")
                    Spacer()
                    vpnToggle
                }
                selectVPN
                selectionRegion
            }
        }
    }
    
    private var premiumProxyToggle: some View {
        HStack {
            GlassPillToggle(
                isOn: Binding(
                    get: { viewModel.settings.isPremiumProxyEnabled },
                    set: { viewModel.togglePremiumProxy($0) }
                ),
                isDisabled: !viewModel.settings.isVPNEnabled
            )
            getLabel("Premium Proxy")
        }
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
            isDisabled: false
        )
    }
    
    private var selectVPN: some View {
        HStack {
            getLabel("Select VPN")
            Spacer()
            BrowserJetMenuPicker(
                options: VPNType.allCases,
                selection: Binding(
                    get: { viewModel.settings.selectedVPN ?? .vpn1 },
                    set: { viewModel.updateSelectedVPN($0) }
                ),
                isDisabled: !viewModel.settings.areVPNControlsEnabled,
                width: K.vpnPickerWidth,
                label: { $0.rawValue }
            )
        }
    }
    
    private var selectionRegion: some View {
        HStack {
            getLabel("Select Region")
            Spacer()
            BrowserJetMenuPicker(
                options: RegionType.allCases,
                selection: Binding(
                    get: { viewModel.settings.selectedRegion ?? .uk },
                    set: { viewModel.updateSelectedRegion($0) }
                ),
                isDisabled: !viewModel.settings.areRegionControlsEnabled,
                width: K.regionPickerWidth,
                label: { $0.rawValue }
            )
        }
    }
}

#Preview {
    LauncherView()
}
