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
        let appPath = Bundle.main.bundlePath

        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/sh")
        task.arguments = [
            "-c",
            "sleep 1; /usr/bin/open -n \"$1\"",
            "relauncher",
            appPath
        ]

        do {
            try task.run()
            QuitConfirmationController.terminateWithoutConfirmation()
        } catch {
            AppLogger.error("Failed to relaunch app: \(error.localizedDescription)")
        }
    }
}
