//
//  AppUtils.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 27/04/2026.
//

import AppKit

enum AppUtils {
    static func getAppMarketingVersion() -> String {
        Bundle.main.appVersion
    }

    static func getAppBuildVersion() -> Int {
        Int(Bundle.main.buildNumber) ?? 0
    }

    static var macOSManualDownloadURL: URL? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "MACOS_MANUAL_DOWNLOAD_URL") as? String else {
            return nil
        }

        let cleanedValue = value.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
        return URL(string: cleanedValue)
    }

    @MainActor
    static func relaunchApplication() {
        let appURL = Bundle.main.bundleURL

        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        configuration.createsNewApplicationInstance = true
        NSWorkspace.shared.openApplication(at: appURL, configuration: configuration) { _, _ in }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            QuitConfirmationController.terminateWithoutConfirmation()
        }
    }
}
