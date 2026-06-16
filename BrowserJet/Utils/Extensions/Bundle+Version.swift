//
//  Bundle+Version.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 28/04/2026.
//

import Foundation

extension Bundle {
    /// App version (e.g. "3.8.2")
    var appVersion: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    }

    /// Build number (e.g. "7")
    var buildNumber: String {
        infoDictionary?["CFBundleVersion"] as? String ?? "0"
    }

    /// Combined version + build (e.g. "3.8.2 (7)")
    var fullVersion: String {
        "\(appVersion) (\(buildNumber))"
    }
}
