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
    let authProxy: AuthProxy?

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

    let webView: WKWebView

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

        // Log VPN details when tab is initialized
        if let proxy = authProxy {
            AppLogger.info(
                "TabModel initialized with VPN - Tab ID: \(id), Slot: \(sessionSlot), IP: \(proxy.host), Port: \(proxy.port), Username: \(proxy.username), Password: \(proxy.password)"
            )
        } else {
            AppLogger.info("TabModel initialized - Tab ID: \(id), Slot: \(sessionSlot), Proxy: None (Local connection)")
        }

        self.startedAsAboutBlank = (startURL.absoluteString == "about:blank")
        self.hasNavigatedAwayFromInitialBlank = !self.startedAsAboutBlank

        let config = WKWebViewConfiguration()
        config.websiteDataStore = dataStore

        self.webView = WKWebView(frame: .zero, configuration: config)

        if let userAgent = userAgent {
            self.webView.customUserAgent = userAgent
        }

        self.addressText = startURL.absoluteString

        let delegate = TabNavigationDelegate(tab: self, onOpenInNewTab: onOpenInNewTab)
        self.navigationDelegate = delegate
        self.webView.navigationDelegate = delegate

        // Load the initial URL (skip blank)
        if startURL.absoluteString != "about:blank" {
            load(startURL)
        }
    }

    /// Update the callback for opening new tabs (can be set after initialization)
    func setOnOpenInNewTab(_ callback: @escaping (URL) -> Void) {
        navigationDelegate?.setOnOpenInNewTab(callback)
    }
}

// MARK: - Navigation
extension TabModel {
    func load(_ url: URL) {
        addressText = url.absoluteString
        webView.load(URLRequest(url: url))
    }

    func load(_ input: String) {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if trimmed.contains("://"), let url = URL(string: trimmed) {
            load(url); return
        }

        if trimmed.contains(".") && !trimmed.contains(" "),
           let url = URL(string: "https://\(trimmed)") {
            load(url); return
        }

        let encodedQuery = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? trimmed
        if let url = URL(string: "https://www.google.com/search?q=\(encodedQuery)") {
            load(url)
        }
    }
}

// MARK: - Tab Navigation Delegate
private final class TabNavigationDelegate: NSObject, WKNavigationDelegate {
    private weak var tab: TabModel?
    private var onOpenInNewTab: ((URL) -> Void)?
    private var titleObservation: NSKeyValueObservation?
    private var urlObservation: NSKeyValueObservation?
    private var loadingTimeoutTask: Task<Void, Never>?

    init(tab: TabModel, onOpenInNewTab: ((URL) -> Void)? = nil) {
        self.tab = tab
        self.onOpenInNewTab = onOpenInNewTab
        super.init()
        setupObservations(for: tab)
    }

    func setOnOpenInNewTab(_ callback: @escaping (URL) -> Void) {
        self.onOpenInNewTab = callback
    }

    private func setupObservations(for tab: TabModel) {
        titleObservation = tab.webView.observe(\.title, options: [.new]) { [weak tab] _, _ in
            guard let tab else { return }
            Task { @MainActor in
                let trimmedTitle = tab.webView.title?.trimmingCharacters(in: .whitespacesAndNewlines)
                tab.title = (trimmedTitle?.isEmpty == false) ? trimmedTitle ?? "New Tab" : "New Tab"
            }
        }

        urlObservation = tab.webView.observe(\.url, options: [.new]) { [weak tab] _, _ in
            guard let tab else { return }
            Task { @MainActor in
                let newURLString = tab.webView.url?.absoluteString
                tab.addressText = newURLString ?? tab.addressText

                if tab.hasNavigatedAwayFromInitialBlank == false,
                   let newURLString,
                   newURLString != "about:blank" {
                    tab.hasNavigatedAwayFromInitialBlank = true
                }
            }
        }
    }

    deinit {
        loadingTimeoutTask?.cancel()
        titleObservation = nil
        urlObservation = nil
    }

    // swiftlint:disable:next implicitly_unwrapped_optional
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        Task { @MainActor [weak self] in
            guard let tab = self?.tab else { return }
            tab.isLoading = true
            tab.canGoBack = webView.canGoBack
            tab.canGoForward = webView.canGoForward

            self?.loadingTimeoutTask?.cancel()
            self?.loadingTimeoutTask = Task { [weak self] in
                try? await Task.sleep(nanoseconds: 30_000_000_000)
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    guard let tab = self?.tab else { return }
                    if tab.isLoading {
                        AppLogger.warning("Navigation timeout - resetting loading state for tab \(tab.id)")
                        tab.isLoading = false
                    }
                }
            }
        }
    }

    // swiftlint:disable:next implicitly_unwrapped_optional
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        Task { @MainActor [weak self] in
            guard let tab = self?.tab else { return }
            if let title = webView.title, !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                tab.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            if let url = webView.url {
                tab.addressText = url.absoluteString
            }
        }
    }

    // swiftlint:disable:next implicitly_unwrapped_optional
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        loadingTimeoutTask?.cancel()
        loadingTimeoutTask = nil

        Task { @MainActor [weak self] in
            guard let tab = self?.tab else { return }
            tab.isLoading = false
            tab.canGoBack = webView.canGoBack
            tab.canGoForward = webView.canGoForward
            tab.addressText = webView.url?.absoluteString ?? tab.addressText

            if let title = webView.title, !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                tab.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        // Fetch favicon (best-effort)
        let javascript = """
        (function() {
          const rels = ["icon", "shortcut icon", "apple-touch-icon", "apple-touch-icon-precomposed"];
          for (const r of rels) {
            const el = document.querySelector(`link[rel='${r}']`) || document.querySelector(`link[rel~='${r}']`);
            if (el && el.href) return el.href;
          }
          return null;
        })();
        """

        webView.evaluateJavaScript(javascript) { [weak tab] result, _ in
            guard let tab else { return }
            let iconString = result as? String
            let fallback = webView.url.flatMap { url -> URL? in
                guard let host = url.host else { return nil }
                return URL(string: "\(url.scheme ?? "https")://\(host)/favicon.ico")
            }

            let iconURL = (iconString.flatMap { URL(string: $0) }) ?? fallback
            guard let iconURL else { return }

            Task {
                do {
                    let (data, _) = try await URLSession.shared.data(from: iconURL)
                    if let image = NSImage(data: data) {
                        await MainActor.run { tab.favicon = image }
                    }
                } catch { }
            }
        }
    }

    // swiftlint:disable:next implicitly_unwrapped_optional
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        loadingTimeoutTask?.cancel()
        loadingTimeoutTask = nil

        Task { @MainActor [weak self] in
            guard let tab = self?.tab else { return }
            tab.isLoading = false
            tab.canGoBack = webView.canGoBack
            tab.canGoForward = webView.canGoForward
            AppLogger.warning("Navigation failed for tab \(tab.id): \(error.localizedDescription)")
        }
    }

    // swiftlint:disable:next implicitly_unwrapped_optional
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        loadingTimeoutTask?.cancel()
        loadingTimeoutTask = nil

        Task { @MainActor [weak self] in
            guard let tab = self?.tab else { return }
            tab.isLoading = false
            tab.canGoBack = webView.canGoBack
            tab.canGoForward = webView.canGoForward
            tab.addressText = webView.url?.absoluteString ?? tab.addressText
            AppLogger.warning("Provisional navigation failed for tab \(tab.id): \(error.localizedDescription)")
        }
    }

    func webView(
        _ webView: WKWebView,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard let tab else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        if let proxyType = challenge.protectionSpace.proxyType,
           proxyType == kCFProxyTypeHTTP as String || proxyType == kCFProxyTypeHTTPS as String {
            guard let proxy = tab.authProxy else {
                completionHandler(.performDefaultHandling, nil)
                return
            }

            let credential = URLCredential(user: proxy.username, password: proxy.password, persistence: .forSession)
            completionHandler(.useCredential, credential)
            return
        }

        completionHandler(.performDefaultHandling, nil)
    }

    // MARK: - New tab routing

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        if navigationAction.targetFrame == nil,
           let url = navigationAction.request.url {
            if isSeatGeekCheckoutURL(url) {
                openInSameTab(url, webView: webView)
                decisionHandler(.cancel)
                return
            }

            if let callback = onOpenInNewTab {
                callback(url)
                decisionHandler(.cancel)
                return
            }
        }

        decisionHandler(.allow)
    }

    private func isSeatGeekCheckoutURL(_ url: URL) -> Bool {
        guard let host = url.host?.lowercased() else { return false }
        guard host == "seatgeek.com" || host.hasSuffix(".seatgeek.com") else { return false }
        return url.path.lowercased().hasPrefix("/checkout")
    }

    private func openInSameTab(_ url: URL, webView: WKWebView) {
        webView.load(URLRequest(url: url))
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
