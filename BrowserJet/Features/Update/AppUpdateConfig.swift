//
//  AppUpdateConfig.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 26/06/2026.
//

import Foundation

struct AppUpdateConfig: Decodable {
    
    static let supportedSchemaVersion = 1
    
    let schemaVersion: Int
    let latestVersion: String
    let latestBuildVersion: Int
    let minimumSupportedVersion: String
    let minimumSupportedBuildVersion: Int
    let optionalUpdateEnabled: Bool
    let macOSDownloadURL: String
    
    var isSupported: Bool {
        schemaVersion <= Self.supportedSchemaVersion
    }
    
    init(
        schemaVersion: Int = 1,
        latestVersion: String,
        latestBuildVersion: Int,
        minimumSupportedVersion: String,
        minimumSupportedBuildVersion: Int,
        optionalUpdateEnabled: Bool,
        macOSDownloadURL: String
    ) {
        self.schemaVersion = schemaVersion
        self.latestVersion = latestVersion
        self.latestBuildVersion = latestBuildVersion
        self.minimumSupportedVersion = minimumSupportedVersion
        self.minimumSupportedBuildVersion = minimumSupportedBuildVersion
        self.optionalUpdateEnabled = optionalUpdateEnabled
        self.macOSDownloadURL = macOSDownloadURL
    }
}

extension AppUpdateConfig {
    static var defaultJSONString: String {
        let downloadURL = AppUtils.macOSManualDownloadURL?.absoluteString ?? "https://browserjet.com/download-file"
        return """
        {
          "schemaVersion": 1,
          "latestVersion": "\(AppUtils.getAppMarketingVersion())",
          "latestBuildVersion": \(AppUtils.getAppBuildVersion()),
          "minimumSupportedVersion": "3.8.0",
          "minimumSupportedBuildVersion": 0,
          "optionalUpdateEnabled": false,
          "macOSDownloadURL": "\(downloadURL)"
        }
        """
    }
    
    /// In-memory fallback when Firebase is unreachable and JSON cannot be produced.
    static var `default`: AppUpdateConfig {
        AppUpdateConfig(
            latestVersion: AppUtils.getAppMarketingVersion(),
            latestBuildVersion: AppUtils.getAppBuildVersion(),
            minimumSupportedVersion: "3.8.0",
            minimumSupportedBuildVersion: 0,
            optionalUpdateEnabled: false,
            macOSDownloadURL: AppUtils.macOSManualDownloadURL?.absoluteString ?? "https://browserjet.com/download-file"
        )
    }
}
