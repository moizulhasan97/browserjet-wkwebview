//
//  LauncherSettings.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 12/02/2026.
//

struct LauncherSettings {
    // Required fields
    var address: String

    // Tab configuration
    var numberOfTabs: LauncherTabPreset

    // VPN/Proxy configuration
    var isVPNEnabled: Bool
    var isPremiumProxyEnabled: Bool
    var selectedVPN: VPNType?
    var selectedRegion: RegionType?

    // Manage My Proxy (custom) configuration
    var customProxyGroupID: String?
    var customProxyGroupName: String?
    var customProxyRotation: ProxyRotationType = .linear
    /// Refreshed by `LauncherViewModel` on appear and right after "Use My Proxy" succeeds.
    var customProxySnapshot: [AuthProxy] = []

    var isCustomProxyModeActive: Bool { customProxyGroupID != nil }

    var isValid: Bool {
        !address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var areVPNControlsEnabled: Bool {
        isVPNEnabled && !isPremiumProxyEnabled && !isCustomProxyModeActive
    }

    var areRegionControlsEnabled: Bool {
        isVPNEnabled && !isPremiumProxyEnabled && selectedVPN != .vpn1 && !isCustomProxyModeActive
    }

    mutating func clearCustomProxyMode() {
        customProxyGroupID = nil
        customProxyGroupName = nil
        customProxySnapshot = []
    }
}

extension LauncherSettings {
    func resolvedProxyType() -> ProxyType {
        if isCustomProxyModeActive, let groupID = customProxyGroupID {
            return .proxy(.custom(groupID: groupID, groupName: customProxyGroupName ?? "Custom"))
        }

        guard isVPNEnabled else { return .local }

        if isPremiumProxyEnabled, let region = selectedRegion, let vpn = selectedVPN {
            return .proxy(.premium(vpn: vpn, region: region))
        }

        if let vpn = selectedVPN, let region = selectedRegion {
            return .proxy(.builtIn(vpn: vpn, region: region))
        }

        return .local
    }
}
