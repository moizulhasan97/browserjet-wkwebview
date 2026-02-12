//
//  LauncherRootView.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 12/02/2026.
//


import SwiftUI

struct LauncherRootView: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager
    
    let appConfiguration: AppConfiguration
    
    var body: some View {
        LauncherView()
            .environment(\.appTheme, themeManager.theme(for: colorScheme))
            .environment(\.appConfiguration, appConfiguration)
    }
}
