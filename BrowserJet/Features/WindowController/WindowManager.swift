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

    enum ActivationLayout {
        case fullForm
        case progressOnly
        case infoAlert
        case shiftLicense

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

    private var activationWC: (any ShowableWindowController)?
    private var launcherWC: (any ShowableWindowController)?
    private var browserWC: (any ShowableWindowController)?

    private var lastActivationFullFormContentHeight: CGFloat?

    private let browserWindowSize = NSSize(width: 1200, height: 780)
    private let browserCornerRadius: CGFloat = 18

    private init() {}

    func resizeActivationWindowToFit(_ layout: ActivationLayout) {
        guard let windowController = activationWC as? BrowserJetWindowController<BrowserJetWindowRoot> else { return }

        let compact = layout != .fullForm
        windowController.setActivationChromeBorderless(compact)

        guard let contentSize = layout.contentSize else { return }
        lastActivationFullFormContentHeight = nil
        windowController.applyFixedContentSize(contentSize)
    }

    func resizeActivationFullFormToContentHeight(_ measuredHeight: CGFloat) {
        guard measuredHeight > 0,
            let windowController = activationWC as? BrowserJetWindowController<BrowserJetWindowRoot> else { return }

        let height = ActivationWindowMetrics.clampedContentHeight(measuredHeight)

        if let last = lastActivationFullFormContentHeight, abs(last - height) < 1 {
            return
        }

        lastActivationFullFormContentHeight = height

        windowController.setActivationChromeBorderless(false)
        windowController.applyFixedContentSize(
            NSSize(width: ActivationWindowMetrics.contentWidth, height: height)
        )
    }

    func showActivation(
        themeManager: ThemeManager,
        sessionManager: SessionManager,
        appConfiguration: AppConfiguration
    ) {
        if activationWC == nil {
            let storedKey = Self.hasStoredLicenseKey()

            let initialSize: NSSize = if storedKey {
                ActivationLayout.progressOnly.contentSize ?? NSSize(width: 400, height: 220)
            } else {
                ActivationWindowMetrics.placeholderContentSize
            }

            let rootView = BrowserJetWindowRoot()
                .environmentObject(themeManager)
                .environmentObject(sessionManager)
                .environmentObject(LicenseAccountStore.shared)
                .environment(\.appConfiguration, appConfiguration)

            activationWC = BrowserJetWindowController(
                content: rootView,
                size: initialSize,
                titleBarHidden: false,
                resizable: false,
                cornerRadius: 18,
                borderlessChrome: storedKey
            )
        }

        activationWC?.show()
    }

    @MainActor
    func dismissActivationAndShowLauncher(
        themeManager: ThemeManager,
        sessionManager: SessionManager,
        appConfiguration: AppConfiguration
    ) {
        activationWC?.close()
        activationWC = nil

        showLauncher(
            themeManager: themeManager,
            sessionManager: sessionManager,
            appConfiguration: appConfiguration
        )
    }

    @MainActor
    func showLauncher(
        themeManager: ThemeManager,
        sessionManager: SessionManager,
        appConfiguration: AppConfiguration
    ) {
        launcherWC?.close()
        launcherWC = nil

        let rootView = LauncherRootView(appConfiguration: appConfiguration)
            .environmentObject(themeManager)
            .environmentObject(sessionManager)
            .environmentObject(LicenseAccountStore.shared)

        let isTrialUser = LicenseAccountStore.shared.isTrialUser
        let launcherHeight: CGFloat = isTrialUser ? 562 : 530// 506
        let intendedSize = NSSize(width: 500, height: launcherHeight)

        launcherWC = BrowserJetWindowController(
            content: rootView,
            size: intendedSize,
            titleBarHidden: false,
            resizable: false,
            cornerRadius: 18
        )

        launcherWC?.show()
    }

    @MainActor
    func showBrowser(
        request: LaunchRequest,
        themeManager: ThemeManager,
        sessionManager: SessionManager,
        appConfiguration: AppConfiguration
    ) {
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

        let menu = BrowserMenuBuilder.from(RemoteConfigManager.shared.menuConfiguration)
        let rootView = BrowserRootView(state: state, menu: menu)
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

        launcherWC?.close()
        launcherWC = nil

        browserWC?.show()
    }

    @MainActor
    func showBrowserForTrialExpired(
        paymentURL: URL,
        themeManager: ThemeManager,
        sessionManager: SessionManager,
        appConfiguration: AppConfiguration
    ) {
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

        let menu = BrowserMenuBuilder.from(RemoteConfigManager.shared.menuConfiguration)
        let rootView = BrowserRootView(state: state, menu: menu)
            .environmentObject(themeManager)
            .environmentObject(sessionManager)
            .environmentObject(LicenseAccountStore.shared)
            .environment(\.appConfiguration, appConfiguration)

        activationWC?.close()
        activationWC = nil

        launcherWC?.close()
        launcherWC = nil

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
    }

    private static func hasStoredLicenseKey() -> Bool {
        guard let raw = UserDefaults.standard.object(forKey: StorageKeys.licenseKey) as? String else {
            return false
        }

        return !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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
