//
//  RemoteConfigKey.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 24/04/2026.
//

import Foundation

enum RemoteConfigKey: String, CaseIterable, Sendable {
    case forceUpdateEnabled = "force_update_enabled"
    case menuConfig = "menu_config"
    case appUpdateConfig = "app_update_config"
    case featureFlagsConfig = "feature_flags_config"
    case endpointsConfig = "endpoints_config"
    case builtInVPNConfig = "builtin_vpn_config"

    /// Keys whose values carry credentials. Their values are never written to logs.
    var isSensitive: Bool {
        self == .builtInVPNConfig
    }
}
