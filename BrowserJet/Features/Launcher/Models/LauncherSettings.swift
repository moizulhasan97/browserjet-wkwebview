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
    func resolvedProxyType() -> ProxyType {
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
