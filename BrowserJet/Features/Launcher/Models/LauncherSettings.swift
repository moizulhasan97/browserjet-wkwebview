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
    
    var canTogglePremiumProxy: Bool {
        isVPNEnabled && !isPremiumProxyEnabled
    }
    
    var areVPNControlsEnabled: Bool {
        isVPNEnabled && !isPremiumProxyEnabled
    }
    
    var areRegionControlsEnabled: Bool {
        isVPNEnabled && !isPremiumProxyEnabled
    }
}
