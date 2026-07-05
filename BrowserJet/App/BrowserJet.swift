//
//  BrowserJet.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 12/02/2026.
//

import SwiftUI
import Firebase
import Sparkle

@main
struct BrowserJet: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self)
    private var appDelegate
    private let themeManager = ThemeManager()
    private let sessionManager = SessionManager(
        maxSessions: AppEnvironment.currentConfiguration.maxBrowserTabs
    )
    private let updaterController: SPUStandardUpdaterController
    private let sparkleUpdaterDelegate = SparkleUpdaterDelegate()

    var body: some Scene {
        Settings {
            SettingsRootView()
                .environmentObject(themeManager)
        }.commands {
            CommandGroup(after: .appInfo) {
                CheckForUpdatesView(updater: updaterController.updater)
            }
            BrowserCommands(themeManager: themeManager)
        }
    }

    init() {
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: sparkleUpdaterDelegate,
            userDriverDelegate: nil
        )
        ForceUpdateGate.shared.register(updaterController: updaterController)
        SparkleUpdateCoordinator.shared.register(updaterController)
        FirebaseApp.configure()
        CrashReportingManager.shared.configure()
        CrashReportingManager.shared.log("app: launch started")
        Task { @MainActor in
            await RemoteConfigManager.shared.fetchAndActivate()
            let flags = RemoteConfigManager.shared.resolvedFeatureFlagsConfig
            CrashReportingManager.shared.applyRemoteFlag(enabled: flags.crashReportingEnabled)
            CrashReportingManager.shared.setCustomValue(
                flags.crashlyticsSummary,
                forKey: CrashReportingManager.CustomKey.activeFeatureFlags
            )
            #if DEBUG
            RemoteConfigManager.shared.debugPrintAllValues()
            #endif
            let updatePolicy = AppUpdatePolicy.evaluateBuild()
            SparkleUpdateCoordinator.shared.applyPolicyResult(
                updatePolicy,
                context: .afterRemoteConfigFetch
            )
        }
        AppLogger.info("App initializing - Environment: \(AppEnvironment.current.displayName)")
        let themeManager = self.themeManager
        let sessionManager = self.sessionManager
        AppLogger.debug("ThemeManager initialized")
        DispatchQueue.main.async {
            themeManager.applyWindowAppearance()
            AppLogger.info("Showing activation window")
            LicenseAccountStore.shared.refresh()
            WindowManager.shared.showActivation(
                themeManager: themeManager,
                sessionManager: sessionManager,
                appConfiguration: AppEnvironment.currentConfiguration
            )
        }
    }
}
