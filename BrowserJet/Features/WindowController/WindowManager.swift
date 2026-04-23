//
//  WindowManager.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 12/02/2026.
//


import AppKit
import Foundation
import SwiftUI

final class WindowManager {
    static let shared = WindowManager()

    /// Content sizes for the activation `BrowserJetWindowRoot` window (title bar is extra frame).
    enum ActivationLayout {
        case fullForm
        case progressOnly
        case infoAlert
        case shiftLicense

        var contentSize: NSSize {
            switch self {
            case .fullForm:
                // Match `showLauncher` (500×639) so activation and post-verify launcher share the same frame.
                return NSSize(width: 500, height: 300)
            case .progressOnly:
                return NSSize(width: 400, height: 220)
            case .infoAlert:
                return NSSize(width: 480, height: 580)
            case .shiftLicense:
                return NSSize(width: 520, height: 460)
            }
        }
    }

    private var launcherWC: (any ShowableWindowController)?
    private var browserWC: (any ShowableWindowController)?

    /// Same size and behavior as launcher-opened browser (show() calls zoom for maximize).
    private let browserWindowSize = NSSize(width: 1200, height: 780)
    private let browserCornerRadius: CGFloat = 18

    private init() {
        AppLogger.debug("WindowManager singleton initialized")
    }

    /// Shrinks or expands the activation window when root is `BrowserJetWindowRoot` (no-op for launcher/browser windows).
    /// Compact layouts use **borderless** `NSWindow` chrome so only the SwiftUI card (e.g. progress) is visible—no title bar behind it.
    func resizeActivationWindowToFit(_ layout: ActivationLayout) {
        guard let wc = launcherWC as? BrowserJetWindowController<BrowserJetWindowRoot> else { return }
        let compact = layout != .fullForm
        wc.setActivationChromeBorderless(compact)
        wc.applyFixedContentSize(layout.contentSize)
    }

    func showActivation(
        themeManager: ThemeManager,
        sessionManager: SessionManager,
        appConfiguration: AppConfiguration
    ) {
        AppLogger.info("showActivation called")
        if launcherWC == nil {
            let storedKey = Self.hasStoredLicenseKey()
            let initialSize = storedKey
                ? ActivationLayout.progressOnly.contentSize
                : ActivationLayout.fullForm.contentSize
            AppLogger.info(
                "Creating activation window - storedKey: \(storedKey), size: \(initialSize.width)x\(initialSize.height), borderless: \(storedKey)"
            )
            let rootView = BrowserJetWindowRoot()
                .environmentObject(themeManager)
                .environmentObject(sessionManager)
                .environmentObject(LicenseAccountStore.shared)
                .environment(\.appConfiguration, appConfiguration)

            launcherWC = BrowserJetWindowController(
                content: rootView,
                size: initialSize,
                titleBarHidden: false,
                resizable: false,
                cornerRadius: 18,
                borderlessChrome: storedKey
            )
            AppLogger.debug("Activation window controller created successfully")
        }
        launcherWC?.show()
        AppLogger.info("Activation window shown")
    }

    private static func hasStoredLicenseKey() -> Bool {
        guard let raw = UserDefaults.standard.object(forKey: StorageKeys.licenseKey) as? String else {
            return false
        }
        return !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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
                .environmentObject(LicenseAccountStore.shared)

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

    /// Close activation window and show the launcher (e.g. after successful activation).
    func dismissActivationAndShowLauncher(
        themeManager: ThemeManager,
        sessionManager: SessionManager,
        appConfiguration: AppConfiguration
    ) {
        launcherWC?.close()
        launcherWC = nil
        AppLogger.info("Activation window closed")
        showLauncher(themeManager: themeManager, sessionManager: sessionManager, appConfiguration: appConfiguration)
    }

    @MainActor
    func showBrowser(
        request: LaunchRequest,
        themeManager: ThemeManager,
        sessionManager: SessionManager,
        appConfiguration: AppConfiguration
    ) {
        // swiftlint:disable:next line_length
        AppLogger.info("showBrowser called - tabs: \(request.numberOfTabs), proxy: \(request.proxyType.statusTitle), address: \(request.address)")
        let vpnProvider = VPNProvider(configurations: appConfiguration.vpnConfigurations)
        let generatedProxies: [AuthProxy]
        if request.proxyType.isPremiumSession {
            generatedProxies = PremiumProxyRepository.shared.authProxiesForSession()
        } else if request.selectedVPN == .vpn1 {
            generatedProxies = VPN1ProxyRepository.shared.authProxiesForSession()
        } else if let vpnID = request.selectedVPN?.rawValue {
            generatedProxies = vpnProvider.generateProxies(for: vpnID)
        } else {
            generatedProxies = []
        }
        
        let initialURL = URL(string: request.address)
            ?? URL(string: appConfiguration.defaultSearchAddress)
            ?? URL(string: "https://www.google.com")
            ?? URL(string: "about:blank")
            ?? URL(string: "about:blank")!

        let state = BrowserWindowState(
            proxyType: request.proxyType,
            isolationMode: request.isolationMode,
            proxies: generatedProxies,
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
            .environmentObject(LicenseAccountStore.shared)

        browserWC = BrowserJetWindowController(
            content: rootView,
            size: browserWindowSize,
            titleBarHidden: false,
            resizable: true,
            cornerRadius: browserCornerRadius
        )

        // Close launcher window before showing browser
        launcherWC?.close()
        launcherWC = nil
        AppLogger.info("Launcher window closed")

        browserWC?.show()
        AppLogger.info("Browser window shown")
    }

    /// When trial or license is expired: open browser with full chrome (same look as launcher). Single tab, payment URL; address bar and non-refresh actions disabled.
    @MainActor
    func showBrowserForTrialExpired(
        paymentURL: URL,
        themeManager: ThemeManager,
        sessionManager: SessionManager,
        appConfiguration: AppConfiguration
    ) {
        AppLogger.info("showBrowserForTrialExpired - URL: \(paymentURL.absoluteString)")
        let state = BrowserWindowState(
            proxyType: .local,
            isolationMode: appConfiguration.sessionIsolationModeValue,
            proxies: [],
            userAgent: appConfiguration.userAgentValue,
            sessionManager: sessionManager,
            initialURL: paymentURL,
            initialTabCount: 1,
            isTrialLockActive: true
        )
        let rootView = BrowserRootView(
            state: state,
            menu: .default
        )
        .environmentObject(themeManager)
        .environmentObject(sessionManager)
        .environmentObject(LicenseAccountStore.shared)
        .environment(\.appConfiguration, appConfiguration)

        launcherWC?.close()
        launcherWC = nil
        AppLogger.info("Activation window closed")

        browserWC = BrowserJetWindowController(
            content: rootView,
            size: browserWindowSize,
            titleBarHidden: false,
            resizable: true,
            cornerRadius: browserCornerRadius
        )
        browserWC?.show()
        AppLogger.info("Browser window shown (payment only)")
    }
}
