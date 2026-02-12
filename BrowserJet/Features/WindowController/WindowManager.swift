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

    private init() {}

    func showLauncher(
        themeManager: ThemeManager,
        sessionManager: SessionManager,
        appConfiguration: AppConfiguration
    ) {
        if launcherWC == nil {
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
        }
        launcherWC?.show()
    }

    //    func showProxyManager() {
    //        if proxyWC == nil {
    //            proxyWC = BrowserJetWindowController(
    //                content: ProxyManagerView(),
    //                size: NSSize(width: 900, height: 600),
    //                resizable: false,
    //                cornerRadius: 18
    //            )
    //        }
    //        proxyWC?.show()
    //    }
}
