//
//  AppConfiguration.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 12/02/2026.
//

import Foundation

struct AppConfiguration {
    private let isUserAgentEnabled: Bool
    private let proxyType: ProxyType
    let defaultSearchAddress: String
    private let sessionIsolationMode: SessionIsolationMode
    let launcherTabPresets: [LauncherTabPreset]
    let vpnConfigurations: [VPNConfiguration]
    let duplicateTabCounts: [Int]
    let maxBrowserTabs: Int
    // More-menu URLs
        let paymentCardURL: URL
        let buyLicensesURL: URL
        let contactUsURL: URL
        let twitterURL: URL
    
    init(
        isUserAgentEnabled: Bool,
        proxyType: ProxyType,
        defaultSearchAddress: String,
        sessionIsolationMode: SessionIsolationMode,
        launcherTabPresets: [LauncherTabPreset],
        vpnConfigurations: [VPNConfiguration],
        duplicateTabCounts: [Int],
        maxBrowserTabs: Int,
        paymentCardURL: URL,
        buyLicensesURL: URL,
        contactUsURL: URL,
        twitterURL: URL
    ) {
        self.isUserAgentEnabled = isUserAgentEnabled
        self.proxyType = proxyType
        self.defaultSearchAddress = defaultSearchAddress
        self.sessionIsolationMode = sessionIsolationMode
        self.launcherTabPresets = launcherTabPresets
        self.vpnConfigurations = vpnConfigurations
        self.duplicateTabCounts = duplicateTabCounts
        self.maxBrowserTabs = maxBrowserTabs
        self.paymentCardURL = paymentCardURL
        self.buyLicensesURL = buyLicensesURL
        self.contactUsURL = contactUsURL
        self.twitterURL = twitterURL
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

    var defaultProxyTypeValue: ProxyType {
        proxyType
    }
}

extension AppConfiguration {
    static let production: AppConfiguration = {
        let config = AppConfiguration(
            isUserAgentEnabled: false,
            proxyType: .local,
            defaultSearchAddress: "https://www.ipchicken.com/",
            sessionIsolationMode: .perTab,
            launcherTabPresets: LauncherTabPreset.allCases,
            vpnConfigurations: [
                VPNConfiguration(
                    id: "vpn1",
                    displayName: "VPN 1",
                    baseIP: "142.173.65.60",
                    portGenerationConfig: PortGenerationConfig(
                           portPattern: .sequential(
                               basePort: 16020,
                               startIndex: 0
                           ),
                           count: 4
                       ),
                    password: "SPQLPBWP",
                    usernameStrategy: .static(username: "Y9PQL"),
                    ipGenerationConfig: IPGenerationConfig(
                        ipPattern: .sequential(
                            baseIP: "142.173.65.60",
                            startIndex: 0
                        ),
                        count: 4
                    )
                ),
                VPNConfiguration(
                    id: "vpn2",
                    displayName: "VPN 2",
                    baseIP: "151.145.134.153",
                    portGenerationConfig: PortGenerationConfig(
                           portPattern: .custom(ports: [
                            14843,
                            14844,
                            14845,
                            7672
                           ]),
                           count: 4
                       ),
                    password: "8YUTNTH5",
                    usernameStrategy: .static(username: "EQKOH"),
                    ipGenerationConfig: .init(
                        ipPattern: .custom(ips: [
                            "151.145.134.153",
                            "151.145.134.154",
                            "151.145.134.155",
                            "151.145.138.122"
                        ]),
                        count: 4
                    )
                )
            ],
            duplicateTabCounts: Array(1...10),
            maxBrowserTabs: 5,
            paymentCardURL: URL(string: "https://www.google.com/payment")!,
            buyLicensesURL: URL(string: "https://www.google.com/buy")!,
            contactUsURL: URL(string: "https://browserjet.com/contact")!,
            twitterURL: URL(string: "https://twitter.com/browserjet")!,
        )
        AppLogger.info("Development configuration initialized - Default address: \(config.defaultSearchAddress)")
        return config
    }()
    
    static let development: AppConfiguration = {
        let config = AppConfiguration(
            isUserAgentEnabled: false,
            proxyType: .local,
            defaultSearchAddress: "https://www.ipchicken.com/",
            sessionIsolationMode: .perTab,
            launcherTabPresets: LauncherTabPreset.allCases,
            vpnConfigurations: [
                VPNConfiguration(
                    id: "vpn1",
                    displayName: "VPN 1",
                    baseIP: "142.173.65.60",
                    portGenerationConfig: PortGenerationConfig(
                           portPattern: .sequential(
                               basePort: 16020,
                               startIndex: 0
                           ),
                           count: 4
                       ),
                    password: "SPQLPBWP",
                    usernameStrategy: .static(username: "Y9PQL"),
                    ipGenerationConfig: IPGenerationConfig(
                        ipPattern: .sequential(
                            baseIP: "142.173.65.60",
                            startIndex: 0
                        ),
                        count: 4
                    )
                ),
                VPNConfiguration(
                    id: "vpn2",
                    displayName: "VPN 2",
                    baseIP: "151.145.134.153",
                    portGenerationConfig: PortGenerationConfig(
                           portPattern: .custom(ports: [
                            14843,
                            14844,
                            14845,
                            7672
                           ]),
                           count: 4
                       ),
                    password: "8YUTNTH5",
                    usernameStrategy: .static(username: "EQKOH"),
                    ipGenerationConfig: .init(
                        ipPattern: .custom(ips: [
                            "151.145.134.153",
                            "151.145.134.154",
                            "151.145.134.155",
                            "151.145.138.122"
                        ]),
                        count: 4
                    )
                )
            ],
            duplicateTabCounts: Array(1...10),
            maxBrowserTabs: 5,
            paymentCardURL: URL(string: "https://www.google.com/payment")!,
            buyLicensesURL: URL(string: "https://www.google.com/buy")!,
            contactUsURL: URL(string: "https://browserjet.com/contact")!,
            twitterURL: URL(string: "https://twitter.com/browserjet")!,
        )
        AppLogger.info("Development configuration initialized - Default address: \(config.defaultSearchAddress)")
        return config
    }()
}
