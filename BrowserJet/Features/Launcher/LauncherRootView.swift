//
//  LauncherRootView.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 12/02/2026.
//

import SwiftUI

/// Launcher window geometry. Height is content-driven; `initialContentHeight` is only used
/// until the first measurement arrives.
enum LauncherWindowMetrics {
    static let contentWidth: CGFloat = 500
    static let initialContentHeight: CGFloat = 530

    static var initialContentSize: NSSize {
        NSSize(width: contentWidth, height: initialContentHeight)
    }
}

// MARK: - Window Root (theme bridge)
struct LauncherRootView: View {
    @Environment(\.colorScheme)
    private var colorScheme

    @EnvironmentObject private var themeManager: ThemeManager

    @ObservedObject private var forceGate = ForceUpdateGate.shared

    let appConfiguration: AppConfiguration

    // private let titleBarCompensation: CGFloat = 28

    var body: some View {
        ZStack(alignment: .top) {
            AppBackgroundStyle
                .brandGradient(
                    for: themeManager.resolvedColorScheme(for: colorScheme)
                )
                .makeView()
                .ignoresSafeArea()

            // Group {
            if forceGate.isBlocking {
                ForceUpdateBlockingOverlay()
            } else {
                LauncherView(appConfiguration: appConfiguration)
                    .environment(\.appConfiguration, appConfiguration)
                    .frame(width: LauncherWindowMetrics.contentWidth)
                    .fixedSize(horizontal: false, vertical: true)
                    // Content height never depends on window height (fixedSize), so resizing can't loop.
                    .onGeometryChange(for: CGFloat.self) { proxy in
                        proxy.size.height
                    } action: { newHeight in
                        WindowManager.shared.resizeLauncherToContentHeight(newHeight)
                    }
            }
            // }
            // .padding(.top, -titleBarCompensation)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .environment(\.appTheme, themeManager.theme(for: colorScheme))
        .environment(\.designSystem, DesignSystem())
        // .brandThemedWindow(themeManager: themeManager)
    }
}
