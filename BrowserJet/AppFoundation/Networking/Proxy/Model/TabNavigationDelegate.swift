//
//  TabNavigationDelegate.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 16/02/2026.
//

import Foundation
import AppKit
import WebKit

private enum WKWebViewFault: Error, LocalizedError {
    case webContentProcessTerminated(tabID: UUID, url: String)

    var errorDescription: String? {
        switch self {
        case .webContentProcessTerminated(let tabID, let url):
            return "WKWebView WebContent process terminated for tab \(tabID) at \(url)"
        }
    }
}

// MARK: - Tab Navigation Delegate
final class TabNavigationDelegate: NSObject, WKNavigationDelegate {
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

    /// Tear down KVO on the old WKWebView and re-attach everything to `newWebView`.
    func rebindWebView(to newWebView: WKWebView) {
        // 1. Tear down old KVO observations
        titleObservation = nil
        urlObservation = nil

        // 2. Cancel any in-flight timeout
        loadingTimeoutTask?.cancel()
        loadingTimeoutTask = nil

        // 3. Re-attach self as navigation delegate on the new web view
        newWebView.navigationDelegate = self

        // 4. Re-setup KVO observations against the new web view
        guard let tab else { return }
        setupObservations(for: tab)
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
        // swiftlint:disable indentation_width
        let javascript = """
        (function() {
          const rels = ["icon", "shortcut icon", "apple-touch-icon", "apple-touch-icon-precomposed"];
          for (const r of rels) {
            const el = document.querySelector(`link[rel='${r}']`)
              || document.querySelector(`link[rel~='${r}']`);
            if (el && el.href) return el.href;
          }
          return null;
        })();
        """
        // swiftlint:enable indentation_width

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
            if (error as NSError).code != NSURLErrorCancelled {
                CrashReportingManager.shared.log(
                    "webview_nav_failed: \(webView.url?.absoluteString ?? "?") - \(error.localizedDescription)"
                )
            }
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
            if (error as NSError).code != NSURLErrorCancelled {
                CrashReportingManager.shared.log(
                    "webview_nav_failed: \(webView.url?.absoluteString ?? "?") - \(error.localizedDescription)"
                )
            }
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
    
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        Task { @MainActor [weak self] in
            guard let tab = self?.tab else { return }
            let url = webView.url?.absoluteString ?? tab.addressText
            AppLogger.error("WebContent process terminated for tab \(tab.id) at \(url)")
            CrashReportingManager.shared.record(
                error: WKWebViewFault.webContentProcessTerminated(tabID: tab.id, url: url)
            )
        }
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
