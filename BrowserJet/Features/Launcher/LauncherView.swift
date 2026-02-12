//
//  LauncherView.swift
//  browserjet-wkwebview
//
//  Created by Moiz Ul Hasan on 10/02/2026.
//

import SwiftUI

fileprivate enum LauncherViewConstants {
    static let interItemSpacing: CGFloat = 25.0,
               launchButtonHeight: CGFloat = 48.0
}

struct LauncherView: View {
    
    @Environment(\.designSystem) private var designSystem
    @Environment(\.appTheme) private var theme
    @Environment(\.appConfiguration) private var config
    @State private var address: String = ""
    @State private var VPNStatus: Bool = false
    @State private var premiumProxyStatus: Bool = false
    @State private var selectedVPN: VPNType = .vpn1
    @State private var selectedRegion: RegionType = .uk
    @State private var selectedPreset: LauncherTabPreset = .one
    private var presets: [LauncherTabPreset] {
        config.launcherTabPresets
    }
    private typealias K = LauncherViewConstants
    
    var body: some View {
        VStack {
            userNameLogo
            searchBarCard
            vpnCard
            launchButton
                .padding(.top, 30)
        }
        .padding()
        .background(AppBackgroundStyle.browserJetGradient.makeView())
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
            isDisabled: false,
            action: didTapLaunch
        )
    }
    
    func didTapLaunch() {
        print("DID TAP LAUNCH")
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
        LauncherSearchField(text: $address)
    }
    
    private var searchBarCard: some View {
        CardContainer {
            VStack (spacing: K.interItemSpacing) {
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
                selection: $selectedPreset,
                isDisabled: false,
                width: 70.0,
                label: { $0.rawValue.toString }
            )
        }
    }
    
    // Bottom card
    private var vpnCard: some View {
        CardContainer {
            VStack (spacing: K.interItemSpacing) {
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
            GlassPillToggle(isOn: $premiumProxyStatus)
            getLabel("Premium Proxy")
        }
    }
    
    private var manageMyProxyButton: some View {
        Button {
            print("OPEN MANAGE MY PROXY")
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
        GlassPillToggle(isOn: $VPNStatus)
    }
    
    private var selectVPN: some View {
        HStack {
            getLabel("Select VPN")
            Spacer()
            BrowserJetMenuPicker(
                options: VPNType.allCases,
                selection: $selectedVPN,
                isDisabled: false,
                width: 70.0,
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
                selection: $selectedRegion,
                isDisabled: false,
                width: 70.0,
                label: { $0.rawValue }
            )
        }
    }
}

#Preview {
    LauncherView()
}
