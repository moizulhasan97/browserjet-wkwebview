//
//  LauncherViewModel.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 12/02/2026.
//

import Combine

@MainActor
final class LauncherViewModel: ObservableObject {
    @Published var settings: LauncherSettings

    private let defaultSearchAddress: String

    init(defaultSearchAddress: String) {
        AppLogger.debug("LauncherViewModel initializing with default address: \(defaultSearchAddress)")
        self.defaultSearchAddress = defaultSearchAddress
        self.settings = LauncherSettings(
            address: "",
            numberOfTabs: .one,
            isVPNEnabled: false,
            isPremiumProxyEnabled: false,
            selectedVPN: .vpn1,
            selectedRegion: .uk
        )
        AppLogger.debug("LauncherViewModel initialized with default settings")
    }

    func onAppear() {
        AppLogger.debug("LauncherView appeared")
    }

    func toggleVPN(_ newValue: Bool) {
        AppLogger.info("VPN toggled to: \(newValue)")
        settings.isVPNEnabled = newValue
        // If VPN is disabled, also disable premium proxy
        if !newValue {
            settings.isPremiumProxyEnabled = false
            AppLogger.debug("VPN disabled, premium proxy also disabled")
        }
    }

    func togglePremiumProxy(_ newValue: Bool) {
        // Only allow toggle if VPN is enabled
        guard settings.isVPNEnabled else {
            AppLogger.warning("Attempted to toggle premium proxy without VPN enabled")
            return
        }
        AppLogger.info("Premium proxy toggled to: \(newValue)")
        settings.isPremiumProxyEnabled = newValue
    }

    func updateAddress(_ address: String) {
        // Only update if the value actually changed to prevent unnecessary updates
        guard settings.address != address else { return }
        AppLogger.debug("Address updated to: \(address)")
        settings.address = address
    }

    func updateNumberOfTabs(_ preset: LauncherTabPreset) {
        AppLogger.info("Number of tabs changed to: \(preset.rawValue)")
        settings.numberOfTabs = preset
    }

    func updateSelectedVPN(_ vpn: VPNType) {
        AppLogger.info("VPN selection changed to: \(vpn.rawValue)")
        settings.selectedVPN = vpn
    }

    func updateSelectedRegion(_ region: RegionType) {
        AppLogger.info("Region selection changed to: \(region.rawValue)")
        settings.selectedRegion = region
    }

    //    func didTapLaunch() {
    //        guard settings.isValid else {
    //            AppLogger.warning("Launch attempted with invalid settings - Address: '\(settings.address)'")
    //            return
    //        }
    //        AppLogger.info("Launch button tapped - Address: '\(settings.address)', Tabs: \(settings.numberOfTabs.rawValue), VPN: \(settings.isVPNEnabled), Premium Proxy: \(settings.isPremiumProxyEnabled), VPN Type: \(settings.selectedVPN?.rawValue ?? "none"), Region: \(settings.selectedRegion?.rawValue ?? "none")")
    //        // TODO: Implement launch logic
    //    }

    func didTapManageMyProxy() {
        AppLogger.info("Manage My Proxy button tapped")
        // TODO: Implement manage proxy logic
    }
}
