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

    //private let titleBarCompensation: CGFloat = 28

    var body: some View {
        ZStack(alignment: .top) {
            AppBackgroundStyle
                .brandGradient(
                    for: themeManager.resolvedColorScheme(for: colorScheme)
                )
                .makeView()
                .ignoresSafeArea()

            //Group {
                if forceGate.isBlocking {
                    ForceUpdateBlockingOverlay()
                } else {
                    LauncherView(appConfiguration: appConfiguration)
                        .environment(\.appConfiguration, appConfiguration)
                }
           // }
            //.padding(.top, -titleBarCompensation)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .environment(\.appTheme, themeManager.theme(for: colorScheme))
        .environment(\.designSystem, DesignSystem())
        //.brandThemedWindow(themeManager: themeManager)
    }
}
