//
//  WindowManager.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 12/02/2026.
//

import AppKit
import Foundation
import SwiftUI

// #region agent log
private func debugLogWM(_ message: String, data: [String: Any] = [:], hypothesisId: String = "") {
    let ts = Int(Date().timeIntervalSince1970 * 1000)
    var payload: [String: Any] = ["sessionId": "73aa8c", "timestamp": ts, "location": "WindowManager.swift", "message": message, "hypothesisId": hypothesisId]
    data.forEach { payload[$0.key] = $0.value }
    let prettyData = data.map { "\($0.key)=\($0.value)" }.sorted().joined(separator: " ")
    print("[BJ-DEBUG-73aa8c] WM | \(message) | \(prettyData)")
    let logPath = NSHomeDirectory() + "/Desktop/browserjet-debug-73aa8c.log"
    if let json = try? JSONSerialization.data(withJSONObject: payload), let line = String(data: json, encoding: .utf8) {
        let full = line + "\n"
        if let fh = FileHandle(forWritingAtPath: logPath) { fh.seekToEndOfFile(); fh.write(Data(full.utf8)); fh.closeFile() }
        else { try? Data(full.utf8).write(to: URL(fileURLWithPath: logPath)) }
    }
}
// #endregion

final class WindowManager {
    static let shared = WindowManager()

    /// Content sizes for the activation `BrowserJetWindowRoot` window (title bar is extra frame).
    enum ActivationLayout {
        case fullForm
        case progressOnly
        case infoAlert
        case shiftLicense

        /// Fixed content size for compact bootstrap layouts. Full form uses measured height instead.
        var contentSize: NSSize? {
            switch self {
            case .fullForm:
                return nil
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
    private var lastActivationFullFormContentHeight: CGFloat?

    /// Same size and behavior as launcher-opened browser (show() calls zoom for maximize).
    private let browserWindowSize = NSSize(width: 1200, height: 780)
    private let browserCornerRadius: CGFloat = 18

    private init() {
        AppLogger.debug("WindowManager singleton initialized")
    }

    /// Shrinks or expands the activation window when root is `BrowserJetWindowRoot` (no-op for launcher/browser windows).
    /// Compact layouts use **borderless** `NSWindow` chrome so only the SwiftUI card (e.g. progress) is visible—no title bar behind it.
    func resizeActivationWindowToFit(_ layout: ActivationLayout) {
        // #region agent log
        let wcType = launcherWC.map { "\(type(of: $0))" } ?? "nil"
        let guardPasses = launcherWC is BrowserJetWindowController<BrowserJetWindowRoot>
        debugLogWM("resizeActivationWindowToFit called", data: ["layout": "\(layout)", "launcherWC_type": wcType, "guardPasses": guardPasses, "compact": layout != .fullForm], hypothesisId: "B")
        // #endregion
        guard let windowController = launcherWC as? BrowserJetWindowController<BrowserJetWindowRoot> else { return }
        let compact = layout != .fullForm
        windowController.setActivationChromeBorderless(compact)
        guard let contentSize = layout.contentSize else { return }
        lastActivationFullFormContentHeight = nil
        windowController.applyFixedContentSize(contentSize)
    }

    /// Sizes the activation window to fit measured full-form content (no ScrollView).
    func resizeActivationFullFormToContentHeight(_ measuredHeight: CGFloat) {
        guard measuredHeight > 0,
              let windowController = launcherWC as? BrowserJetWindowController<BrowserJetWindowRoot> else { return }

        let height = ActivationWindowMetrics.clampedContentHeight(measuredHeight)
        if let last = lastActivationFullFormContentHeight, abs(last - height) < 1 {
            return
        }
        lastActivationFullFormContentHeight = height

        windowController.setActivationChromeBorderless(false)
        windowController.applyFixedContentSize(
            NSSize(width: ActivationWindowMetrics.contentWidth, height: height)
        )
        AppLogger.debug("Activation full form resized to content height \(height)")
    }

    func showActivation(
        themeManager: ThemeManager,
        sessionManager: SessionManager,
        appConfiguration: AppConfiguration
    ) {
        AppLogger.info("showActivation called")
        if launcherWC == nil {
            let storedKey = Self.hasStoredLicenseKey()
            let initialSize: NSSize = if storedKey {
                ActivationLayout.progressOnly.contentSize
                ?? NSSize(width: 400, height: 220)
            } else {
                ActivationWindowMetrics.placeholderContentSize
            }
            AppLogger.info(
                """
                Creating activation window - storedKey: \(storedKey), \
                size: \(initialSize.width)x\(initialSize.height), borderless: \(storedKey)
                """
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
            // #region agent log
            debugLogWM("showLauncher: new BrowserJetWindowController created", data: ["launcherWC_type": launcherWC.map { "\(type(of: $0))" } ?? "nil"], hypothesisId: "A")
            // #endregion
        } else {
            // #region agent log
            debugLogWM("showLauncher: launcherWC was NOT nil - reusing", data: ["launcherWC_type": launcherWC.map { "\(type(of: $0))" } ?? "nil"], hypothesisId: "A")
            // #endregion
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
        // #region agent log
        let visibleWins = NSApp.windows.filter { $0.isVisible }
        let sheetWins = NSApp.windows.filter { $0.isSheet }
        debugLogWM("dismissActivationAndShowLauncher called", data: [
            "launcherWC_isNil": launcherWC == nil,
            "launcherWC_type": launcherWC.map { String(describing: type(of: $0)) } ?? "nil",
            "visible_windows_count": visibleWins.count,
            "sheet_windows_count": sheetWins.count
        ], hypothesisId: "F")
        // #endregion
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
        let builtInRegion = builtInRegion(from: request.proxyType)
        let generatedProxies: [AuthProxy]
        if request.proxyType.isPremiumSession {
            generatedProxies = PremiumProxyRepository.shared.authProxiesForSession()
        } else if request.selectedVPN == .vpn1 {
            generatedProxies = VPN1ProxyRepository.shared.authProxiesForSession()
        } else if let vpnID = request.selectedVPN?.rawValue {
            generatedProxies = vpnProvider.generateProxies(for: vpnID, region: builtInRegion)
        } else {
            generatedProxies = []
        }

        let initialURL = AddressBarURLResolver.resolve(request.address)
            ?? AddressBarURLResolver.resolve(appConfiguration.defaultSearchAddress)
            ?? URL(string: "https://www.google.com")
            ?? URL(string: "about:blank")
            ?? URL(fileURLWithPath: "/")

        let state = BrowserWindowState(
            proxyType: request.proxyType,
            isolationMode: request.isolationMode,
            proxies: generatedProxies,
            userAgent: request.userAgent,
            sessionManager: sessionManager,
            initialURL: initialURL,
            initialTabCount: request.numberOfTabs,
            maxBrowserTabs: appConfiguration.maxBrowserTabs
        )

        let rootView = BrowserRootView(
            state: state,
            menu: .default
        )
            .environmentObject(themeManager)
            .environmentObject(sessionManager)
            .environmentObject(LicenseAccountStore.shared)

        let browserWindowController = BrowserJetWindowController(
            content: rootView,
            size: browserWindowSize,
            titleBarHidden: false,
            resizable: true,
            cornerRadius: browserCornerRadius
        )
        browserWindowController.attachBrowserTabStripTitlebarAccessory(
            state: state,
            themeManager: themeManager,
            sessionManager: sessionManager
        )
        browserWC = browserWindowController

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
            maxBrowserTabs: appConfiguration.maxBrowserTabs,
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

        let browserWindowController = BrowserJetWindowController(
            content: rootView,
            size: browserWindowSize,
            titleBarHidden: false,
            resizable: true,
            cornerRadius: browserCornerRadius
        )
        browserWindowController.attachBrowserTabStripTitlebarAccessory(
            state: state,
            themeManager: themeManager,
            sessionManager: sessionManager
        )
        browserWC = browserWindowController
        browserWC?.show()
        AppLogger.info("Browser window shown (payment only)")
    }

    private func builtInRegion(from proxyType: ProxyType) -> RegionType? {
        guard case .proxy(let source) = proxyType else { return nil }
        switch source {
        case .builtIn(_, let region), .premium(_, let region):
            return region
        case .custom:
            return nil
        }
    }
}
