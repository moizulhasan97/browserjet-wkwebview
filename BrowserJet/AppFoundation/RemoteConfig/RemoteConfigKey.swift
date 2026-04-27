//
//  RemoteConfigKey.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 24/04/2026.
//

import Foundation

enum RemoteConfigKey: String, CaseIterable, Sendable {
    case forceUpdateEnabled = "force_update_enabled"
    case macOSAppMinimumSupportedMarketingVersion = "macos_app_minimum_supported_marketing_version"
    case optionalUpdateEnabled = "optional_update_enabled"
    case macOSAppLatestMarketingVersion = "macos_app_latest_marketing_version"
    case macOSAppLatestBuildVersion = "macos_app_latest_build_version"
    case macOSAppMinimumSupportedBuildVersion = "macos_app_minimum_supported_build_version"
}
