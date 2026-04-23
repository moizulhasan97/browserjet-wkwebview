//
//  LauncherSettings+LaunchRequest.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 17/02/2026.
//

import Foundation

extension LauncherSettings {
    @MainActor
    func makeLaunchRequest(appConfiguration: AppConfiguration) -> LaunchRequest {
        LicenseAccountStore.shared.refresh()
        let isTrialUser = LicenseAccountStore.shared.isTrialUser
        let sanitizedSelectedVPN: VPNType? = {
            guard let selectedVPN else { return nil }
            if isTrialUser && appConfiguration.trialBlockedVPNs.contains(selectedVPN) {
                return nil
            }
            return selectedVPN
        }()

        let proxyType: ProxyType = {
            guard isTrialUser else { return resolvedProxyType() }

            if case .proxy(let source) = resolvedProxyType() {
                switch source {
                case .builtIn(let vpn, _), .premium(let vpn, _):
                    if appConfiguration.trialBlockedVPNs.contains(vpn) {
                        return .local
                    }
                case .custom:
                    break
                }
            }
            return resolvedProxyType()
        }()

        return LaunchRequest(
            address: address,
            numberOfTabs: numberOfTabs.rawValue,
            proxyType: proxyType,
            isolationMode: appConfiguration.sessionIsolationModeValue,
            userAgent: appConfiguration.userAgentValue,
            selectedVPN: sanitizedSelectedVPN
        )
    }
}
