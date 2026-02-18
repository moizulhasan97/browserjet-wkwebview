//
//  LauncherSettings+LaunchRequest.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 17/02/2026.
//

import Foundation

extension LauncherSettings {
    func makeLaunchRequest(appConfiguration: AppConfiguration) -> LaunchRequest {
        LaunchRequest(
            address: address,
            numberOfTabs: numberOfTabs.rawValue,
            proxyType: resolvedProxyType(),
            isolationMode: appConfiguration.sessionIsolationModeValue,
            userAgent: appConfiguration.userAgentValue
        )
    }
}
