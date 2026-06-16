//
//  TabModel.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 16/02/2026.
//

import Foundation
import AppKit
import WebKit

@MainActor
final class TabModel: ObservableObject, Identifiable {
    let id = UUID()
    let sessionSlot: Int

    /// The actual resolved proxy credentials for this tab (nil for local).
    @Published private(set) var authProxy: AuthProxy?

    /// The window-level selection (Local / On VPN / Premium / Custom)
    let proxyType: ProxyType

    private let startedAsAboutBlank: Bool

    @Published var hasNavigatedAwayFromInitialBlank: Bool = false
    @Published var title: String = "New Tab"
    @Published var addressText: String = ""
    @Published var favicon: NSImage?

    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false
    @Published var isLoading: Bool = false

    var shouldHideFaviconSlotForInitialBlank: Bool {
        startedAsAboutBlank && !hasNavigatedAwayFromInitialBlank && favicon == nil
    }

    @Published private(set) var webView: WKWebView
    @Published private(set) var webViewID = UUID()

    /// Set by replaceWebView; consumed by WebViewContainer.makeNSView once the
    /// new WKWebView is in the window and has a real frame.
    var pendingURL: URL?

    // Keep it alive for the lifetime of the tab
    private var navigationDelegate: TabNavigationDelegate?

    init(
        sessionSlot: Int,
        startURL: URL,
        dataStore: WKWebsiteDataStore,
        proxyType: ProxyType,
        authProxy: AuthProxy?,
        userAgent: String?,
        onOpenInNewTab: ((URL) -> Void)? = nil
    ) {
        self.sessionSlot = sessionSlot
        self.proxyType = proxyType
        self.authProxy = authProxy

        self.startedAsAboutBlank = (startURL.absoluteString == "about:blank")
        self.hasNavigatedAwayFromInitialBlank = !self.startedAsAboutBlank

        let config = WKWebViewConfiguration()
        config.websiteDataStore = dataStore

        self.webView = WKWebView(frame: .zero, configuration: config)
        TabModel.configureAppearance(self.webView)

        if let userAgent = userAgent {
            self.webView.customUserAgent = userAgent
        }

        self.addressText = startURL.absoluteString

        let delegate = TabNavigationDelegate(tab: self, onOpenInNewTab: onOpenInNewTab)
        self.navigationDelegate = delegate
        self.webView.navigationDelegate = delegate

        // Load the initial URL (skip blank)
        if startURL.absoluteString != "about:blank" {
            webView.load(URLRequest(url: startURL))
        }
    }

    /// Update the callback for opening new tabs (can be set after initialization)
    func setOnOpenInNewTab(_ callback: @escaping (URL) -> Void) {
        navigationDelegate?.setOnOpenInNewTab(callback)
    }
}

// MARK: - Appearance
private extension TabModel {
    /// Removes the opaque white backing from WKWebView so that blank new tabs
    /// show the app gradient instead of flashing white on focus or during loads.
    /// Pages that paint their own background (CSS `background-color`) are unaffected.
    static func configureAppearance(_ webView: WKWebView) {
        // Suppress the white opaque layer drawn by WKScrollView before content loads.
        webView.setValue(false, forKey: "drawsBackground")
        // Match the rubber-band / over-scroll area to the system window color so
        // it adapts correctly when the user switches between light and dark mode.
        webView.underPageBackgroundColor = .windowBackgroundColor
    }
}

// MARK: - Navigation
extension TabModel {
    func load(_ url: URL) {
        addressText = url.absoluteString
        webView.load(URLRequest(url: url))
    }

    func load(_ input: String) {
        guard let url = AddressBarURLResolver.resolve(input) else { return }
        load(url)
    }
}

extension TabModel {
    func updateAuthProxy(_ newProxy: AuthProxy?) {
        self.authProxy = newProxy
    }
}

// MARK: - Burn (proxy replacement)
extension TabModel {
    func replaceWebView(
        newStore: WKWebsiteDataStore,
        url: URL,
        userAgent: String?
    ) {
        // 1. Build the new WKWebView
        let config = WKWebViewConfiguration()
        config.websiteDataStore = newStore
        let newWebView = WKWebView(frame: .zero, configuration: config)
        TabModel.configureAppearance(newWebView)

        if let userAgent {
            newWebView.customUserAgent = userAgent
        }

        // 2. Swap the web view on self BEFORE rebinding the delegate,
        //    so that KVO closures that read tab.webView get the new instance.
        webView = newWebView

        // 3. Re-attach the navigation delegate (tears down old KVO, sets up new)
        navigationDelegate?.rebindWebView(to: newWebView)

        // 4. Re-attach the UI delegate (WebViewContainer.Coordinator).
        //    It will be re-set by updateNSView after SwiftUI re-renders,
        //    but set it now so nothing is missed during the load.
        // (uiDelegate is intentionally left — WebViewContainer handles it)

        // 5. Reset nav state
        canGoBack = false
        canGoForward = false
        favicon = nil
        isLoading = false

        // 6. Store the URL for WebViewContainer.makeNSView to load AFTER the new
        //    WKWebView is placed into the window with a real frame. Loading before
        //    that causes WebKit to stall rendering on the zero-frame, windowless view,
        //    so the page content only appears when a tab switch forces a re-render.
        addressText = url.absoluteString
        pendingURL = url

        // 7. Bump the ID so SwiftUI destroys the old WebViewContainer and calls
        //    makeNSView on a fresh one — that's where the load is triggered.
        webViewID = UUID()

        AppLogger.info("TabModel web view replaced - Tab ID: \(id), URL: \(url.absoluteString)")
    }
}

#if DEBUG
extension TabModel {
    static func preview(
        addressText: String,
        title: String,
        isLoading: Bool,
        favicon: NSImage?,
        webView: WKWebView = WKWebView()
    ) -> TabModel {
        let store = WKWebsiteDataStore.nonPersistent()
        // swiftlint:disable:next force_unwrapping
        let blankURL = URL(string: "about:blank") ?? URL(string: "about:blank")!
        let tab = TabModel(
            sessionSlot: 0,
            startURL: blankURL,
            dataStore: store,
            proxyType: .local,
            authProxy: nil,
            userAgent: nil
        )

        tab.addressText = addressText
        tab.title = title
        tab.isLoading = isLoading
        tab.favicon = favicon
        return tab
    }
}
#endif
