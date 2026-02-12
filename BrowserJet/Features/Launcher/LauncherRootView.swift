//
//  LauncherRootView.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 12/02/2026.
//


import SwiftUI

struct LauncherRootView: View {
    @Environment(\.colorScheme)
    private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager

    let appConfiguration: AppConfiguration

    var body: some View {
        let _ = AppLogger.debug("LauncherRootView body computed - ColorScheme: \(colorScheme == .dark ? "dark" : "light")")
        return LauncherView()
            .environment(\.appTheme, themeManager.theme(for: colorScheme))
            .environment(\.appConfiguration, appConfiguration)
    }
}
