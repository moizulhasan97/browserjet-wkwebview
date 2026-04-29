//
//  LauncherRootView.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 12/02/2026.
//

import SwiftUI

// MARK: - Window Root (theme bridge)
struct LauncherRootView: View {
    @Environment(\.colorScheme)
    private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager
    @ObservedObject private var forceGate = ForceUpdateGate.shared
    let appConfiguration: AppConfiguration
    
    var body: some View {
        AppLogger.debug("LauncherRootView body computed - ColorScheme: \(colorScheme == .dark ? "dark" : "light")")
        return Group {
            if forceGate.isBlocking {
                ForceUpdateBlockingOverlay()
            } else {
                LauncherView(appConfiguration: appConfiguration)
                    .environment(\.appConfiguration, appConfiguration)
            }
        }
        .environment(\.appTheme, themeManager.theme(for: colorScheme))
        .environment(\.designSystem, DesignSystem())
        .task { @MainActor in
            let updatePolicy = AppUpdatePolicy.evaluateBuild()
            SparkleUpdateCoordinator.shared.applyPolicyResult(
                updatePolicy,
                context: .launcherAppeared
            )
        }
    }
}
