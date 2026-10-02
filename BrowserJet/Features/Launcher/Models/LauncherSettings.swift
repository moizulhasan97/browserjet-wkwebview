//
//  LauncherSettings.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 12/02/2026.
//

struct LauncherSettings {
    // Required fields
    var address: String

    // Tab configuration. A plain count (not `LauncherTabPreset`) because the plan's own limit, which may be
    // any Remote Config value, is also selectable.
    var numberOfTabs: Int

    // VPN/Proxy configuration
    var isVPNEnabled: Bool
    var isPremiumProxyEnabled: Bool
    var selectedVPN: VPNType?
    var selectedRegion: RegionType?

    var isValid: Bool {
        !address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var areVPNControlsEnabled: Bool {
        isVPNEnabled && !isPremiumProxyEnabled
    }

    var areRegionControlsEnabled: Bool {
        isVPNEnabled && !isPremiumProxyEnabled
    }
}

extension LauncherSettings {
    /// Premium Proxy is checked first and no longer requires the VPN toggle: Basic has Premium Proxy without
    /// a VPN tier. For Pro the result is unchanged, because the launcher only lets Premium Proxy be on while
    /// the VPN toggle is on.
    func resolvedProxyType() -> ProxyType {
        if isPremiumProxyEnabled {
            return .proxy(.premium)
        }

        guard isVPNEnabled, let vpn = selectedVPN, let region = selectedRegion else {
            return .local
        }
        return .proxy(.builtIn(vpn: vpn, region: region))
    }
}
