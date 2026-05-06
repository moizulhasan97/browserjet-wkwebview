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
    
    static func relaunchApplication() {
        let appURL = Bundle.main.bundleURL
        
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        task.arguments = [appURL.path]
        
        do {
            try task.run()
            AppLogger.info("AppUtils: relaunch command sent")
        } catch {
            AppLogger.error("AppUtils: failed to relaunch app - \(error.localizedDescription)")
        }
        
        NSApplication.shared.terminate(nil)
    }
}
