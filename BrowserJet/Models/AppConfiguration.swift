//
//  AppConfiguration.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 12/02/2026.
//

import Foundation

struct AppConfiguration {
    private let isUserAgentEnabled: Bool
    let defaultSearchAddress: String
    private let sessionIsolationMode: SessionIsolationMode
    let launcherTabPresets: [LauncherTabPreset]
    let vpnConfigurations: [VPNConfiguration]
    let duplicateTabCounts: [Int]
    let maxBrowserTabs: Int
    // More-menu URLs
    // let paymentCardURL: URL
    // let buyLicensesURL: URL
    // let contactUsURL: URL
    // let twitterURL: URL
    // Blocked VPNs for trial users
    let trialBlockedVPNs: Set<VPNType>
    let vpnAllowedRegions: [VPNType: [RegionType]]

    init(
        isUserAgentEnabled: Bool,
        defaultSearchAddress: String,
        sessionIsolationMode: SessionIsolationMode,
        launcherTabPresets: [LauncherTabPreset],
        vpnConfigurations: [VPNConfiguration],
        duplicateTabCounts: [Int],
        maxBrowserTabs: Int,
        // paymentCardURL: URL,
        // buyLicensesURL: URL,
        // contactUsURL: URL,
        // twitterURL: URL,
        trialBlockedVPNs: Set<VPNType>,
        vpnAllowedRegions: [VPNType: [RegionType]]
    ) {
        self.isUserAgentEnabled = isUserAgentEnabled
        self.defaultSearchAddress = defaultSearchAddress
        self.sessionIsolationMode = sessionIsolationMode
        self.launcherTabPresets = launcherTabPresets
        self.vpnConfigurations = vpnConfigurations
        self.duplicateTabCounts = duplicateTabCounts
        self.maxBrowserTabs = maxBrowserTabs
        // self.paymentCardURL = paymentCardURL
        // self.buyLicensesURL = buyLicensesURL
        // self.contactUsURL = contactUsURL
        // self.twitterURL = twitterURL
        self.trialBlockedVPNs = trialBlockedVPNs
        self.vpnAllowedRegions = vpnAllowedRegions
    }
}

extension AppConfiguration {
    var sessionIsolationModeValue: SessionIsolationMode {
        sessionIsolationMode
    }

    var userAgentValue: String? {
        guard isUserAgentEnabled else { return nil }
        return UserAgentPreset.safariMacOS.rawUserAgentString
    }
}

extension AppConfiguration {
    /// Built-in VPN tiers. Each tier's pool (hosts, credentials, session range) is delivered by
    /// Remote Config `builtin_vpn_config` under `pools.<id>`; nothing is bundled in the app.
    private static let builtInVPNConfigurations: [VPNConfiguration] = [
        VPNConfiguration(
            id: VPNType.vpn1.rawValue,
            displayName: "VPN 1",
            layout: .remoteConfigPool
        )
    ]

    /// Regions offered per tier. The launcher lists them alphabetically.
    private static let builtInVPNAllowedRegions: [VPNType: [RegionType]] = [
        .vpn1: [.au, .ca, .nl, .nz, .uae, .uk, .us]
    ]

    static let production: AppConfiguration = {
        let config = AppConfiguration(
            isUserAgentEnabled: true,
            defaultSearchAddress: "https://www.ipchicken.com/",
            sessionIsolationMode: .perTab,
            launcherTabPresets: LauncherTabPreset.allCases,
            vpnConfigurations: AppConfiguration.builtInVPNConfigurations,
            duplicateTabCounts: Array(1...20),
            maxBrowserTabs: 20,
            // paymentCardURL: URL(string: "https://www.google.com/payment")!,
            // buyLicensesURL: URL(string: "https://www.google.com/buy")!,
            // contactUsURL: URL(string: "https://browserjet.com/contact")!,
            // twitterURL: URL(string: "https://twitter.com/browserjet")!,
            trialBlockedVPNs: [],
            vpnAllowedRegions: AppConfiguration.builtInVPNAllowedRegions
        )
        AppLogger.info("Production configuration initialized - Default address: \(config.defaultSearchAddress)")
        return config
    }()

    static let development: AppConfiguration = {
        let config = AppConfiguration(
            isUserAgentEnabled: true,
            defaultSearchAddress: "https://www.ipchicken.com/",
            sessionIsolationMode: .perTab,
            launcherTabPresets: LauncherTabPreset.allCases,
            vpnConfigurations: AppConfiguration.builtInVPNConfigurations,
            duplicateTabCounts: Array(1...20),
            maxBrowserTabs: 20,
            // paymentCardURL: URL(string: "https://www.google.com/payment")!,
            // buyLicensesURL: URL(string: "https://www.google.com/buy")!,
            // contactUsURL: URL(string: "https://browserjet.com/contact")!,
            // twitterURL: URL(string: "https://twitter.com/browserjet")!,
            trialBlockedVPNs: [],
            vpnAllowedRegions: AppConfiguration.builtInVPNAllowedRegions
        )
        AppLogger.info("Development configuration initialized - Default address: \(config.defaultSearchAddress)")
        return config
    }()
}
