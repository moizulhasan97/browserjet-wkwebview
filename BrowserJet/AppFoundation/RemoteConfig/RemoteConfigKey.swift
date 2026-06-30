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
    case macOSManualDownloadURL = "macos_manual_download_url"
    case baseServerURL = "base_server_url"
    case baseWebURL = "base_web_url"
    case updateCardPath = "update_card_path"
    case buyMoreLicensesPath = "buy_more_licenses_path"
    case contactUsPath = "contact_us_path"
    case twitterURL = "twitter_url"
    case shortcutsEnabled = "shortcuts_enabled"
    case browserPurchasePath = "browser_purchase_path"
}
