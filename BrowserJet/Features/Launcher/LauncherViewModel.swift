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
    private let vpnProvider: VPNProvider

    /// Regions offered for the selected tier, in alphabetical order.
    var regionPickerOptions: [RegionType] {
        Self.allowedRegions(for: settings.selectedVPN, policy: vpnAllowedRegions)
    }

    /// True when built-in VPN is selected but its pool is not usable yet (e.g. Remote Config not delivered).
    var isSelectedVPNUnavailable: Bool {
        guard settings.areVPNControlsEnabled, let vpn = settings.selectedVPN else { return false }
        return !vpnProvider.isAvailable(vpn)
    }

    init(
        defaultSearchAddress: String,
        appConfiguration: AppConfiguration,
        vpnProvider: VPNProvider? = nil
    ) {
        AppLogger.debug("LauncherViewModel initializing with default address: \(defaultSearchAddress)")

        LicenseAccountStore.shared.refresh()
        let trial = LicenseAccountStore.shared.isTrialUser
        let blocked = appConfiguration.trialBlockedVPNs

        self.isTrialUser = trial
        self.blockedVPNsForTrial = blocked
        self.defaultSearchAddress = defaultSearchAddress
        if let vpnProvider {
            self.vpnProvider = vpnProvider
        } else {
            self.vpnProvider = VPNProvider(
                configurations: appConfiguration.vpnConfigurations,
                templateProvider: RemoteConfigManager.shared
            )
        }

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
            await refreshVPNPoolsIfUnavailable()
            await premiumRefresh
        }
    }

    /// Launch is blocked when VPN + Premium is selected but the GPP list is empty,
    /// or when the selected built-in VPN has no usable pool.
    func isLaunchAllowed() -> Bool {
        guard settings.isValid else { return false }
        guard settings.isVPNEnabled else { return true }
        if settings.isPremiumProxyEnabled {
            return PremiumProxyRepository.shared.hasPremiumProxies
        }
        return !isSelectedVPNUnavailable
    }

    /// Re-fetches Remote Config when an offered tier has no pool yet (e.g. the app started offline).
    private func refreshVPNPoolsIfUnavailable() async {
        guard availableVPNs.contains(where: { !vpnProvider.isAvailable($0) }) else { return }
        AppLogger.info("LauncherViewModel: built-in VPN pool missing — re-fetching Remote Config")
        await RemoteConfigManager.shared.fetchAndActivate()
    }

    func toggleVPN(_ newValue: Bool) {
        if newValue && availableVPNs.isEmpty {
            AppLogger.warning("VPN toggle ignored — no VPN options available")
            return
        }
        AppLogger.info("VPN toggled to: \(newValue)")
        AnalyticsManager.shared.log(.vpnToggled(enabled: newValue))
        settings.isVPNEnabled = newValue
        if newValue {
            applyDefaultBuiltInVPNSelection()
        } else {
            settings.isPremiumProxyEnabled = false
            premiumProxyUnavailableMessage = nil
            AppLogger.debug("VPN disabled, premium proxy also disabled")
        }
    }

    /// Keeps the current tier when it is still offered; otherwise selects the first offered tier.
    private func applyDefaultBuiltInVPNSelection() {
        let isSelectionOffered = settings.selectedVPN.map { availableVPNs.contains($0) } ?? false
        if !isSelectionOffered {
            settings.selectedVPN = availableVPNs.first
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
        AnalyticsManager.shared.log(.premiumProxyToggled(enabled: newValue))
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
        guard regionPickerOptions.contains(region) else {
            AppLogger.warning("Region \(region.rawValue) is not offered for the selected VPN")
            return
        }
        AppLogger.info("Region selection changed to: \(region.rawValue)")
        settings.selectedRegion = region
    }

    /// Sorted by display code so the picker order never depends on how the policy is written.
    private static func allowedRegions(for vpn: VPNType?, policy: [VPNType: [RegionType]]) -> [RegionType] {
        let regions = vpn.flatMap { policy[$0] } ?? RegionType.allCases
        return regions.sorted { $0.rawValue < $1.rawValue }
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
