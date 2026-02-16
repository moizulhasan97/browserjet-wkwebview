//
//  WindowManager.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 12/02/2026.
//


import AppKit
import SwiftUI

final class WindowManager {
    static let shared = WindowManager()

    private var launcherWC: (any ShowableWindowController)?
    // private var proxyWC: BrowserJetWindowController<ProxyManagerView>?

    private init() {
        AppLogger.debug("WindowManager singleton initialized")
    }

    func showLauncher(
        themeManager: ThemeManager,
        sessionManager: SessionManager,
        appConfiguration: AppConfiguration
    ) {
        AppLogger.info("showLauncher called - Default address: \(appConfiguration.defaultSearchAddress)")
        if launcherWC == nil {
            AppLogger.info("Creating new launcher window - Size: 500x639, Corner radius: 18")
            let rootView = LauncherRootView(appConfiguration: appConfiguration)
                .environmentObject(themeManager)
                .environmentObject(sessionManager) // TODO: - Check we if need this

            launcherWC = BrowserJetWindowController(
                content: rootView,
                size: NSSize(width: 500, height: 639),
                titleBarHidden: false,
                resizable: false,
                cornerRadius: 18
            )
            AppLogger.debug("Launcher window controller created successfully")
        } else {
            AppLogger.debug("Launcher window already exists, reusing existing window")
        }
        launcherWC?.show()
        AppLogger.info("Launcher window shown")
    }
}
