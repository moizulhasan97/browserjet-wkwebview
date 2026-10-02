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
    /// Every built-in VPN tier this build ships. The plan decides which of them are offered (`availableVPNs`).
    private let configuredVPNs: [VPNType]
    private let tabPresets: [LauncherTabPreset]
    private let vpnAllowedRegions: [VPNType: [RegionType]]
    private let vpnProvider: VPNProvider
    private let entitlementsProvider: PlanEntitlementsProviding

    /// The current plan's entitlements. Read on demand (not cached) so the launcher follows licence refreshes
    /// and Remote Config activations while it is open; `LauncherView` reconciles selections when it changes.
    var entitlements: PlanEntitlements {
        entitlementsProvider.currentEntitlements()
    }

    /// VPN tiers the plan grants. Empty for Basic and Trial by default, which hides the whole VPN section.
    var availableVPNs: [VPNType] {
        let current = entitlements
        return configuredVPNs.filter { current.allows($0) }
    }

    var isVPNSectionVisible: Bool {
        !availableVPNs.isEmpty
    }

    var isPremiumProxySectionVisible: Bool {
        entitlements.isPremiumProxyAllowed
    }

    /// Pro keeps the existing UX (Premium Proxy sits under the VPN toggle). Without a VPN section (Basic),
    /// Premium Proxy stands on its own; otherwise a Basic user who bought GPP could never turn it on.
    var premiumProxyRequiresVPNToggle: Bool {
        isVPNSectionVisible
    }

    /// "No. of Tabs" options, capped by the plan.
    var tabCountOptions: [Int] {
        LauncherTabPreset.tabCountOptions(upTo: entitlements.maxTabs, presets: tabPresets)
    }

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
        vpnProvider: VPNProvider? = nil,
        entitlementsProvider: PlanEntitlementsProviding? = nil
    ) {
        AppLogger.debug("LauncherViewModel initializing with default address: \(defaultSearchAddress)")

        LicenseAccountStore.shared.refresh()
        let entitlementsProvider = entitlementsProvider ?? LicensePlanEntitlementsProvider()
        let initialEntitlements = entitlementsProvider.currentEntitlements()

        self.entitlementsProvider = entitlementsProvider
        self.defaultSearchAddress = defaultSearchAddress
        if let vpnProvider {
            self.vpnProvider = vpnProvider
        } else {
            self.vpnProvider = VPNProvider(
                configurations: appConfiguration.vpnConfigurations,
                templateProvider: RemoteConfigManager.shared
            )
        }

        let configuredVPNs = VPNType.from(configurations: appConfiguration.vpnConfigurations)
        self.configuredVPNs = configuredVPNs
        self.tabPresets = appConfiguration.launcherTabPresets
        self.vpnAllowedRegions = appConfiguration.vpnAllowedRegions

        let initialVPN = configuredVPNs.first { initialEntitlements.allows($0) }
        let initialRegion = Self.pickInitialRegion(for: initialVPN, policy: appConfiguration.vpnAllowedRegions)

        self.settings = LauncherSettings(
            address: "",
            numberOfTabs: 1,
            isVPNEnabled: false,
            isPremiumProxyEnabled: false,
            selectedVPN: initialVPN,
            selectedRegion: initialRegion
        )

        AppLogger.debug(
            """
            LauncherViewModel initialized - plan \(initialEntitlements.planID.rawValue), \
            max tabs \(initialEntitlements.maxTabs)
            """
        )
    }

    func onAppear() {
        AppLogger.debug("LauncherView appeared")
        reconcileWithEntitlements()
        Task { @MainActor in
            async let premiumRefresh: Void = refreshPremiumProxiesIfAllowed()
            await refreshVPNPoolsIfUnavailable()
            await premiumRefresh
        }
    }

    /// Launch is blocked when Premium Proxy is selected but the GPP list is empty,
    /// or when the selected built-in VPN has no usable pool.
    func isLaunchAllowed() -> Bool {
        guard settings.isValid else { return false }
        if settings.isPremiumProxyEnabled {
            return PremiumProxyRepository.shared.hasPremiumProxies
        }
        guard settings.isVPNEnabled else { return true }
        return !isSelectedVPNUnavailable
    }

    /// Builds the launch request against the latest licence, after pulling selections back inside the plan.
    /// `nil` means the launch was cancelled; the launcher has been reconciled, so it now shows the plan's options.
    func makeLaunchRequest(appConfiguration: AppConfiguration) -> LaunchRequest? {
        LicenseAccountStore.shared.refresh()
        let requestedConnection = settings.resolvedProxyType()
        reconcileWithEntitlements()
        // A plan change can land at click time (e.g. a downgrade). Never swap the connection the user chose for a
        // different one (VPN → local would expose their real IP); stay on the updated launcher instead.
        guard settings.resolvedProxyType() == requestedConnection else {
            AppLogger.warning("Launch cancelled — the selected connection is no longer included in the plan")
            CrashReportingManager.shared.log("launcher: launch cancelled - connection changed by plan")
            return nil
        }
        return settings.makeLaunchRequest(appConfiguration: appConfiguration, entitlements: entitlements)
    }

    /// Brings the launcher's selections back inside the current plan.
    ///
    /// Why: entitlements can change while the launcher is open (licence re-check, Remote Config activation);
    /// a hidden VPN toggle must not stay switched on, and the tab count must not exceed the new limit.
    func reconcileWithEntitlements() {
        let current = entitlements

        if settings.numberOfTabs > current.maxTabs {
            AppLogger.info("Tab count \(settings.numberOfTabs) exceeds plan limit - clamped to \(current.maxTabs)")
            settings.numberOfTabs = current.maxTabs
        }

        if settings.isPremiumProxyEnabled && !current.isPremiumProxyAllowed {
            AppLogger.info("Premium Proxy is not included in plan \(current.planID.rawValue) - turned off")
            settings.isPremiumProxyEnabled = false
            premiumProxyUnavailableMessage = nil
        }

        let offered = availableVPNs
        guard !offered.isEmpty else {
            if settings.isVPNEnabled {
                AppLogger.info("VPN is not included in plan \(current.planID.rawValue) - turned off")
                settings.isVPNEnabled = false
            }
            return
        }
        if settings.isPremiumProxyEnabled && !settings.isVPNEnabled {
            // Upgraded while Premium Proxy was on standalone: Pro nests it under the VPN toggle, so mirror that
            // state, otherwise the Premium Proxy toggle would be disabled while still on.
            settings.isVPNEnabled = true
        }
        if !(settings.selectedVPN.map { offered.contains($0) } ?? false) {
            settings.selectedVPN = offered.first
            reconcileRegionForSelectedVPN()
        }
    }

    /// Only plans that include Premium Proxy need the GPP list; skipping it saves a request per launcher open.
    private func refreshPremiumProxiesIfAllowed() async {
        guard entitlements.isPremiumProxyAllowed else { return }
        await PremiumProxyRepository.shared.refreshFromNetworkIfPossible()
    }

    /// Re-fetches Remote Config when an offered tier has no pool yet (e.g. the app started offline).
    /// Only tiers in the plan are checked, so Basic (which is never served pools) doesn't re-fetch on every open.
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
        } else if premiumProxyRequiresVPNToggle {
            settings.isPremiumProxyEnabled = false
            premiumProxyUnavailableMessage = nil
            AppLogger.debug("VPN disabled, premium proxy also disabled")
        }
    }

    /// Keeps the current tier when it is still offered; otherwise selects the first offered tier.
    private func applyDefaultBuiltInVPNSelection() {
        let offered = availableVPNs
        let isSelectionOffered = settings.selectedVPN.map { offered.contains($0) } ?? false
        if !isSelectionOffered {
            settings.selectedVPN = offered.first
        }
        reconcileRegionForSelectedVPN()
    }

    func togglePremiumProxy(_ newValue: Bool) {
        guard entitlements.isPremiumProxyAllowed else {
            AppLogger.warning("Premium proxy toggle ignored — not included in plan \(entitlements.planID.rawValue)")
            return
        }
        guard !premiumProxyRequiresVPNToggle || settings.isVPNEnabled else {
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

    func updateNumberOfTabs(_ count: Int) {
        let clamped = min(max(1, count), entitlements.maxTabs)
        AppLogger.info("Number of tabs changed to: \(clamped)")
        settings.numberOfTabs = clamped
    }

    func updateSelectedVPN(_ vpn: VPNType) {
        guard entitlements.allows(vpn) else {
            AppLogger.warning("Blocked VPN selection not included in plan: \(vpn.rawValue)")
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
