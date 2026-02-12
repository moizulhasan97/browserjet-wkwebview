//
//  AppConfiguration.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 12/02/2026.
//

struct AppConfiguration {
    private let isUserAgentEnabled: Bool
    private let proxyType: ProxyType
    let defaultSearchAddress: String
    private let sessionIsolationMode: SessionIsolationMode
    let launcherTabPresets: [LauncherTabPreset]

    init(
        isUserAgentEnabled: Bool,
        proxyType: ProxyType,
        defaultSearchAddress: String,
        sessionIsolationMode: SessionIsolationMode,
        launcherTabPresets: [LauncherTabPreset]
    ) {
        self.isUserAgentEnabled = isUserAgentEnabled
        self.proxyType = proxyType
        self.defaultSearchAddress = defaultSearchAddress
        self.sessionIsolationMode = sessionIsolationMode
        self.launcherTabPresets = launcherTabPresets
    }
}

extension AppConfiguration {
    static let production = AppConfiguration(
        isUserAgentEnabled: false,
        proxyType: .proxy,
        defaultSearchAddress: "https://www.google.com/",
        sessionIsolationMode: .perTab,
        launcherTabPresets: LauncherTabPreset.allCases
    )

    static let development = AppConfiguration(
        isUserAgentEnabled: false,
        proxyType: .proxy,
        defaultSearchAddress: "https://www.google.com/",
        sessionIsolationMode: .perTab,
        launcherTabPresets: LauncherTabPreset.allCases
    )
}
