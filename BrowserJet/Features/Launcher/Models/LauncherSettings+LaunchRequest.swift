//
//  LauncherSettings+LaunchRequest.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 17/02/2026.
//

import Foundation

extension LauncherSettings {
    /// Builds the launch request, enforcing the plan one last time (defence in depth behind the launcher UI,
    /// replacing the old trial-only `trialBlockedVPNs` check).
    ///
    /// Returns `nil` when the selected connection isn't part of the plan. Why not fall back to `.local` as
    /// before: silently launching unproxied when the user chose a VPN would expose their real IP.
    func makeLaunchRequest(
        appConfiguration: AppConfiguration,
        entitlements: PlanEntitlements
    ) -> LaunchRequest? {
        let proxyType = resolvedProxyType()
        guard entitlements.allows(proxyType) else {
            AppLogger.warning(
                "Launch blocked: \(proxyType.statusTitle) is not included in plan \(entitlements.planID.rawValue)"
            )
            CrashReportingManager.shared.log("launcher: launch blocked - connection not in plan")
            return nil
        }

        return LaunchRequest(
            address: address,
            numberOfTabs: min(max(1, numberOfTabs), entitlements.maxTabs),
            maxTabs: entitlements.maxTabs,
            proxyType: proxyType,
            isolationMode: appConfiguration.sessionIsolationModeValue,
            userAgent: appConfiguration.userAgentValue
        )
    }
}
