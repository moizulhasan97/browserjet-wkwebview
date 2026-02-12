//
//  LauncherViewModel.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 12/02/2026.
//

import SwiftUI
import Combine

@MainActor
final class LauncherViewModel: ObservableObject {
    @Published var settings: LauncherSettings

    private let defaultSearchAddress: String

    init(defaultSearchAddress: String) {
        self.defaultSearchAddress = defaultSearchAddress
        self.settings = LauncherSettings(
            address: "",
            numberOfTabs: .one,
            isVPNEnabled: false,
            isPremiumProxyEnabled: false,
            selectedVPN: .vpn1,
            selectedRegion: .uk
        )
    }

    func onAppear() {
        if settings.address.isEmpty {
            settings.address = defaultSearchAddress
        }
    }

    func toggleVPN(_ newValue: Bool) {
        settings.isVPNEnabled = newValue
        // If VPN is disabled, also disable premium proxy
        if !newValue {
            settings.isPremiumProxyEnabled = false
        }
    }

    func togglePremiumProxy(_ newValue: Bool) {
        // Only allow toggle if VPN is enabled
        guard settings.isVPNEnabled else { return }
        settings.isPremiumProxyEnabled = newValue
    }

    func updateAddress(_ address: String) {
        settings.address = address
    }

    func updateNumberOfTabs(_ preset: LauncherTabPreset) {
        settings.numberOfTabs = preset
    }

    func updateSelectedVPN(_ vpn: VPNType) {
        settings.selectedVPN = vpn
    }

    func updateSelectedRegion(_ region: RegionType) {
        settings.selectedRegion = region
    }

    func didTapLaunch() {
        guard settings.isValid else { return }
        // TODO: Implement launch logic
    }

    func didTapManageMyProxy() {
        // TODO: Implement manage proxy logic
    }
}
