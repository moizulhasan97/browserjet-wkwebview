//
//  AppUtils.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 27/04/2026.
//

import Foundation

enum AppUtils {
    static func getAppMarketingVersion() -> String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    }
    
    static func getAppBuildVersion() -> Int {
        Int(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0") ?? 0
    }
}
