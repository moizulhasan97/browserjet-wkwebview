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
            defaultSearchAddress: "https://www.google.com/",
            sessionIsolationMode: .perTab,
            launcherTabPresets: LauncherTabPreset.allCases
        )
        AppLogger.info("Production configuration initialized - Default address: \(config.defaultSearchAddress)")
        return config
    }()

    static let development: AppConfiguration = {
        let config = AppConfiguration(
            isUserAgentEnabled: false,
            proxyType: .local,
            defaultSearchAddress: "https://www.google.com/",
            sessionIsolationMode: .perTab,
            launcherTabPresets: LauncherTabPreset.allCases
        )
        AppLogger.info("Development configuration initialized - Default address: \(config.defaultSearchAddress)")
        return config
    }()
}
