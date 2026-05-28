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
        return nil
    }
}

extension AppConfiguration {
    static let production: AppConfiguration = {
        let config = AppConfiguration(
            isUserAgentEnabled: false,
            defaultSearchAddress: "https://www.ipchicken.com/",
            sessionIsolationMode: .perTab,
            launcherTabPresets: LauncherTabPreset.allCases,
            vpnConfigurations: [
                VPNConfiguration(
                    id: "vpn1",
                    displayName: "VPN 1",
                    layout: .remoteManaged
                ),
                VPNConfiguration(
                    id: "vpn2",
                    displayName: "VPN 2",
                    layout: .datatude(
                        DatatudePoolConfig(
                            host: "rotating.prox-e.io",
                            port: 5055,
                            password: "mkdb1458!2025",
                            counterRange: 11...99_999,
                            counterDigitWidth: 8
                        )
                    )
                )
            ],
            duplicateTabCounts: Array(1...10),
            maxBrowserTabs: 5,
            // paymentCardURL: URL(string: "https://www.google.com/payment")!,
            // buyLicensesURL: URL(string: "https://www.google.com/buy")!,
            // contactUsURL: URL(string: "https://browserjet.com/contact")!,
            // twitterURL: URL(string: "https://twitter.com/browserjet")!,
            trialBlockedVPNs: [.vpn1],
            vpnAllowedRegions: [
                .vpn1: [.us],
                .vpn2: [.uk, .us, .ca, .it, .nz, .au, .uae, .nl]
            ]
        )
        AppLogger.info("Development configuration initialized - Default address: \(config.defaultSearchAddress)")
        return config
    }()

    static let development: AppConfiguration = {
        let config = AppConfiguration(
            isUserAgentEnabled: false,
            defaultSearchAddress: "https://www.ipchicken.com/",
            sessionIsolationMode: .perTab,
            launcherTabPresets: LauncherTabPreset.allCases,
            vpnConfigurations: [
                VPNConfiguration(
                    id: "vpn1",
                    displayName: "VPN 1",
                    layout: .remoteManaged
                ),
                VPNConfiguration(
                    id: "vpn2",
                    displayName: "VPN 2",
                    layout: .datatude(
                        DatatudePoolConfig(
                            host: "rotating.prox-e.io",
                            port: 5055,
                            password: "mkdb1458!2025",
                            counterRange: 11...99_999,
                            counterDigitWidth: 8
                        )
                    )
                )
            ],
            duplicateTabCounts: Array(1...10),
            maxBrowserTabs: 5,
            // paymentCardURL: URL(string: "https://www.google.com/payment")!,
            // buyLicensesURL: URL(string: "https://www.google.com/buy")!,
            // contactUsURL: URL(string: "https://browserjet.com/contact")!,
            // twitterURL: URL(string: "https://twitter.com/browserjet")!,
            trialBlockedVPNs: [.vpn1],
            vpnAllowedRegions: [
                .vpn1: [.us],
                .vpn2: [.uk, .us, .ca, .it, .nz, .au, .uae, .nl]
            ]
        )
        AppLogger.info("Development configuration initialized - Default address: \(config.defaultSearchAddress)")
        return config
    }()
}
