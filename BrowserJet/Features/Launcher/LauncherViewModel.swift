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

    /// Set when the user tries to enable Premium Proxy while the GPP list is empty; cleared when appropriate from the view.
    @Published var premiumProxyUnavailableMessage: String?

    private let defaultSearchAddress: String
    let availableVPNs: [VPNType]

    private(set) var isTrialUser: Bool = false

    private let blockedVPNsForTrial: Set<VPNType>
    private let vpnAllowedRegions: [VPNType: [RegionType]]

    var regionPickerOptions: [RegionType] {
        guard let vpn = settings.selectedVPN else { return RegionType.allCases }
        return vpnAllowedRegions[vpn] ?? RegionType.allCases
    }

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

        self.vpnAllowedRegions = appConfiguration.vpnAllowedRegions
        let initialVPN = filtered.first
        let initialRegion = Self.pickInitialRegion(for: initialVPN, policy: appConfiguration.vpnAllowedRegions)

        self.settings = LauncherSettings(
            address: "",
            numberOfTabs: .one,
            isVPNEnabled: false,
            isPremiumProxyEnabled: false,
            selectedVPN: initialVPN,
            selectedRegion: initialRegion
        )

        AppLogger.debug("LauncherViewModel initialized with default settings")
    }

    func onAppear() {
        AppLogger.debug("LauncherView appeared")
        Task { @MainActor in
            async let premiumRefresh: Void = PremiumProxyRepository.shared.refreshFromNetworkIfPossible()
            async let vpn1Refresh: Void = VPN1ProxyRepository.shared.refreshFromNetworkIfPossible()
            await premiumRefresh
            await vpn1Refresh
            applyDefaultBuiltInVPNSelection()
            reconcileVPN1SelectionIfNeeded()
        }
    }

    /// Launch is blocked when VPN + Premium is selected but the GPP list is empty, or VPN1 is selected without a VPR list.
    func isLaunchAllowed() -> Bool {
        guard settings.isValid else { return false }
        if settings.isVPNEnabled && settings.isPremiumProxyEnabled {
            return PremiumProxyRepository.shared.hasPremiumProxies
        }
        if settings.isVPNEnabled,
            !settings.isPremiumProxyEnabled,
            settings.selectedVPN == .vpn1 {
            return VPN1ProxyRepository.shared.hasVPN1Proxies
        }
        return true
    }

    func toggleVPN(_ newValue: Bool) {
        if newValue && availableVPNs.isEmpty {
            AppLogger.warning("VPN toggle ignored — no VPN options available")
            return
        }
        AppLogger.info("VPN toggled to: \(newValue)")
        settings.isVPNEnabled = newValue
        if newValue {
            applyDefaultBuiltInVPNSelection()
            reconcileVPN1SelectionIfNeeded()
        } else {
            settings.isPremiumProxyEnabled = false
            premiumProxyUnavailableMessage = nil
            AppLogger.debug("VPN disabled, premium proxy also disabled")
        }
    }

    /// Paid: prefer VPN1 when the VPR list loaded; otherwise VPN2 (CEF launcher default). Trial: first allowed tier.
    private func applyDefaultBuiltInVPNSelection() {
        if isTrialUser {
            if let first = availableVPNs.first {
                settings.selectedVPN = first
            }
            reconcileRegionForSelectedVPN()
            return
        }
        if VPN1ProxyRepository.shared.hasVPN1Proxies, availableVPNs.contains(.vpn1) {
            settings.selectedVPN = .vpn1
            AppLogger.info("LauncherViewModel: default built-in VPN → VPN1 (remote list available)")
        } else if availableVPNs.contains(.vpn2) {
            settings.selectedVPN = .vpn2
            AppLogger.info("LauncherViewModel: default built-in VPN → VPN2 (VPN1 list empty or fetch failed)")
        } else if let first = availableVPNs.first {
            settings.selectedVPN = first
        }
        reconcileRegionForSelectedVPN()
    }

    /// If VPN1 is selected but VPR has no rows, fall back to VPN2.
    private func reconcileVPN1SelectionIfNeeded() {
        guard !isTrialUser else { return }
        guard settings.selectedVPN == .vpn1 else { return }
        guard !VPN1ProxyRepository.shared.hasVPN1Proxies else { return }
        if availableVPNs.contains(.vpn2) {
            settings.selectedVPN = .vpn2
            AppLogger.info("LauncherViewModel: reconciled selection VPN1 → VPN2 (no VPN1 proxies)")
        } else if let first = availableVPNs.first {
            settings.selectedVPN = first
        }
        reconcileRegionForSelectedVPN()
    }

    func togglePremiumProxy(_ newValue: Bool) {
        guard settings.isVPNEnabled else {
            AppLogger.warning("Attempted to toggle premium proxy without VPN enabled")
            return
        }
        if newValue && !PremiumProxyRepository.shared.hasPremiumProxies {
            premiumProxyUnavailableMessage = LauncherMessages.premiumNoProxiesAvailable
            AppLogger.warning("Premium proxy toggle ignored — no GPP proxy rows")
            return
        }
        premiumProxyUnavailableMessage = nil
        AppLogger.info("Premium proxy toggled to: \(newValue)")
        settings.isPremiumProxyEnabled = newValue
    }

    func clearPremiumProxyUnavailableMessage() {
        premiumProxyUnavailableMessage = nil
    }

    func updateAddress(_ address: String) {
        guard settings.address != address else { return }
        AppLogger.debug("Address updated to: \(address)")
        settings.address = address
    }

    /// Applies a saved Settings default URL when the launcher still shows the previous default (or is empty).
    func applySavedStartURLIfMatchingDefault(newURL: String, previousDefaultURL: String) {
        let current = settings.address.trimmingCharacters(in: .whitespacesAndNewlines)
        let previous = previousDefaultURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard current.isEmpty || current == previous else {
            AppLogger.debug(
                "Launcher address not updated — user customized (\(current)) away from previous default (\(previous))"
            )
            return
        }
        updateAddress(newURL)
    }

    func updateNumberOfTabs(_ preset: LauncherTabPreset) {
        AppLogger.info("Number of tabs changed to: \(preset.rawValue)")
        settings.numberOfTabs = preset
    }

    func updateSelectedVPN(_ vpn: VPNType) {
        if isTrialUser && blockedVPNsForTrial.contains(vpn) {
            AppLogger.warning("Blocked VPN selection for trial user: \(vpn.rawValue)")
            settings.selectedVPN = availableVPNs.first
            reconcileRegionForSelectedVPN()
            return
        }
        AppLogger.info("VPN selection changed to: \(vpn.rawValue)")
        settings.selectedVPN = vpn
        reconcileRegionForSelectedVPN()
    }

    func updateSelectedRegion(_ region: RegionType) {
        AppLogger.info("Region selection changed to: \(region.rawValue)")
        settings.selectedRegion = region
    }

    func didTapManageMyProxy() {
        AppLogger.info("Manage My Proxy button tapped")
    }

    private static func allowedRegions(for vpn: VPNType?, policy: [VPNType: [RegionType]]) -> [RegionType] {
        guard let vpn else { return RegionType.allCases }
        return policy[vpn] ?? RegionType.allCases
    }

    private static func pickInitialRegion(
        for vpn: VPNType?,
        policy: [VPNType: [RegionType]],
        preferred: RegionType = .uk
    ) -> RegionType {
        let allowed = allowedRegions(for: vpn, policy: policy)
        if allowed.contains(preferred) { return preferred }
        return allowed.first ?? .uk
    }

    private func reconcileRegionForSelectedVPN() {
        guard let vpn = settings.selectedVPN else { return }
        let allowed = Self.allowedRegions(for: vpn, policy: vpnAllowedRegions)
        if let region = settings.selectedRegion, allowed.contains(region) { return }
        settings.selectedRegion = allowed.first
    }
}
