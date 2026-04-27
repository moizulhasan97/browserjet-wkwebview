//
//  BrowserJet.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 12/02/2026.
//

import SwiftUI
import Firebase

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
        FirebaseApp.configure()
        Task { @MainActor in
            await RemoteConfigManager.shared.fetchAndActivate()
            #if DEBUG
            RemoteConfigManager.shared.debugPrintAllValues()
            #endif 
        }
        AppLogger.info("App initializing - Environment: \(AppEnvironment.current.displayName)")
        let themeManager = self.themeManager
        let sessionManager = self.sessionManager
        AppLogger.debug("ThemeManager initialized")
        DispatchQueue.main.async {
            AppLogger.info("Showing activation window")
            LicenseAccountStore.shared.refresh()
            WindowManager.shared.showActivation(
                themeManager: themeManager,
                sessionManager: sessionManager,
                appConfiguration: .development
            )
        }
    }
}
