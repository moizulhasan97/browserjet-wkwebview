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
    private var browserWC: (any ShowableWindowController)?
    
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
                .environmentObject(sessionManager)
            
            launcherWC = BrowserJetWindowController(
                content: rootView,
                size: NSSize(width: 500, height: 639),
                titleBarHidden: false,
                resizable: false,
                cornerRadius: 18
            )
            AppLogger.debug("Launcher window controller created successfully")
        }
        launcherWC?.show()
        AppLogger.info("Launcher window shown")
    }
    
    @MainActor
    func showBrowser(
        request: LaunchRequest,
        proxies: [AuthProxy],
        themeManager: ThemeManager,
        sessionManager: SessionManager,
        appConfiguration: AppConfiguration
    ) {
        AppLogger.info("showBrowser called - tabs: \(request.numberOfTabs), proxy: \(request.proxyType.statusTitle), address: \(request.address)")
        
        let initialURL = URL(string: request.address)
        ?? URL(string: appConfiguration.defaultSearchAddress)!
        
        let state = BrowserWindowState(
            proxyType: request.proxyType,
            isolationMode: request.isolationMode,
            proxies: proxies,
            userAgent: request.userAgent,
            sessionManager: sessionManager,
            initialURL: initialURL,
            initialTabCount: request.numberOfTabs
        )
        
        let rootView = BrowserRootView(
            state: state,
            menu: .default
        )
            .environmentObject(themeManager)
            .environmentObject(sessionManager)
        
        browserWC = BrowserJetWindowController(
            content: rootView,
            size: NSSize(width: 1200, height: 780),
            titleBarHidden: false,
            resizable: true,
            cornerRadius: 18
        )
        
        browserWC?.show()
        AppLogger.info("Browser window shown")
    }
}
