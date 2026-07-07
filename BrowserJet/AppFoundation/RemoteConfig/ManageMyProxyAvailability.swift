//
//  ManageMyProxyAvailability.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 07/07/2026.
//

@MainActor
enum ManageMyProxyAvailability {
    static var isFeatureEnabled: Bool {
        RemoteConfigManager.shared.resolvedFeatureFlagsConfig.manageMyProxyEnabled
    }
    
    static var config: ManageMyProxyConfig {
        RemoteConfigManager.shared.resolvedManageMyProxyConfig
    }
    
    static var availableRotationMethods: [ProxyRotationType] {
        var methods: [ProxyRotationType] = []
        if config.linearRotationEnabled { methods.append(.linear) }
        if config.randomRotationEnabled { methods.append(.random) }
        return methods.isEmpty ? [.linear] : methods
    }
}
