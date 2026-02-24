//
//  BrowserJet.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 12/02/2026.
//

import SwiftUI

@main
struct BrowserJet: App {
    private let themeManager = ThemeManager()
    private let sessionManager = SessionManager()

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }

    init() {
        AppLogger.info("App initializing - Environment: \(AppEnvironment.current.displayName)")
        let themeManager = self.themeManager
        let sessionManager = self.sessionManager
        AppLogger.debug("ThemeManager initialized")
        DispatchQueue.main.async {
            AppLogger.info("Showing activation window")
//            WindowManager.shared.showLauncher(
//                themeManager: themeManager,
//                sessionManager: sessionManager,
//                appConfiguration: .development
//            )
            WindowManager.shared.showActivation(themeManager: themeManager)
        }
    }
}
