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
    let availableVPNs: [VPNType]

    private(set) var isTrialUser: Bool = false

    private let blockedVPNsForTrial: Set<VPNType>

    init(defaultSearchAddress: String, appConfiguration: AppConfiguration) {
        AppLogger.debug("LauncherViewModel initializing with default address: \(defaultSearchAddress)")

        LicenseAccountStore.shared.refresh()
        let trial = LicenseAccountStore.shared.isTrialUser
        let blocked = appConfiguration.trialBlockedVPNs

        self.isTrialUser = trial
        self.blockedVPNsForTrial = blocked
        self.defaultSearchAddress = defaultSearchAddress

        let allVPNs = VPNType.from(configurations: appConfiguration.vpnConfigurations)
        let filtered: [VPNType]
        if trial {
            filtered = allVPNs.filter { !blocked.contains($0) }
        } else {
            filtered = allVPNs
        }
        self.availableVPNs = filtered

        if trial && filtered.isEmpty {
            AppLogger.warning("LauncherViewModel: trial user has no VPN options after applying trialBlockedVPNs")
        }

        self.settings = LauncherSettings(
            address: "",
            numberOfTabs: .one,
            isVPNEnabled: false,
            isPremiumProxyEnabled: false,
            selectedVPN: filtered.first,
            selectedRegion: .uk
        )

        AppLogger.debug("LauncherViewModel initialized with default settings")
    }

    func onAppear() {
        AppLogger.debug("LauncherView appeared")
    }

    func toggleVPN(_ newValue: Bool) {
        if newValue && availableVPNs.isEmpty {
            AppLogger.warning("VPN toggle ignored — no VPN options available")
            return
        }
        AppLogger.info("VPN toggled to: \(newValue)")
        settings.isVPNEnabled = newValue
        if !newValue {
            settings.isPremiumProxyEnabled = false
            AppLogger.debug("VPN disabled, premium proxy also disabled")
        }
    }

    func togglePremiumProxy(_ newValue: Bool) {
        guard settings.isVPNEnabled else {
            AppLogger.warning("Attempted to toggle premium proxy without VPN enabled")
            return
        }
        AppLogger.info("Premium proxy toggled to: \(newValue)")
        settings.isPremiumProxyEnabled = newValue
    }

    func updateAddress(_ address: String) {
        guard settings.address != address else { return }
        AppLogger.debug("Address updated to: \(address)")
        settings.address = address
    }

    func updateNumberOfTabs(_ preset: LauncherTabPreset) {
        AppLogger.info("Number of tabs changed to: \(preset.rawValue)")
        settings.numberOfTabs = preset
    }

    func updateSelectedVPN(_ vpn: VPNType) {
        if isTrialUser && blockedVPNsForTrial.contains(vpn) {
            AppLogger.warning("Blocked VPN selection for trial user: \(vpn.rawValue)")
            settings.selectedVPN = availableVPNs.first
            return
        }
        AppLogger.info("VPN selection changed to: \(vpn.rawValue)")
        settings.selectedVPN = vpn
    }

    func updateSelectedRegion(_ region: RegionType) {
        AppLogger.info("Region selection changed to: \(region.rawValue)")
        settings.selectedRegion = region
    }

    func didTapManageMyProxy() {
        AppLogger.info("Manage My Proxy button tapped")
    }
}
