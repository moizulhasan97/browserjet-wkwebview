//
//  WebViewContainer.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 17/02/2026.
//

import SwiftUI
import WebKit
import Network

struct WebViewContainer: NSViewRepresentable {
    @ObservedObject var tab: TabModel
    let onOpenInNewTab: (URL) -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(tab: tab, onOpenInNewTab: onOpenInNewTab)
    }
    
    func makeNSView(context: Context) -> WKWebView {
        tab.webView.navigationDelegate = context.coordinator
        tab.webView.uiDelegate = context.coordinator
        //tab.webView.addObserver(context.coordinator, forKeyPath: "title", options: .new, context: nil)
        //tab.webView.addObserver(context.coordinator, forKeyPath: "URL", options: .new, context: nil)
        return tab.webView
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {
        // no-op
    }
    
    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        private weak var tab: TabModel?
        private let onOpenInNewTab: (URL) -> Void
        private var titleObservation: NSKeyValueObservation?
        private var urlObservation: NSKeyValueObservation?
        
        init(tab: TabModel, onOpenInNewTab: @escaping (URL) -> Void) {
            self.tab = tab
            self.onOpenInNewTab = onOpenInNewTab
            //        }
            //
            //        override func observeValue(forKeyPath keyPath: String?,
            //                                   of object: Any?,
            //                                   change: [NSKeyValueChangeKey : Any]?,
            //                                   context: UnsafeMutableRawPointer?) {
            //            guard let tab else { return }
            //
            //            if keyPath == "title" {
            //                let t = tab.webView.title?.trimmingCharacters(in: .whitespacesAndNewlines)
            //                if let t, !t.isEmpty { tab.title = t } else { tab.title = "New Tab" }
            //            } else if keyPath == "URL" {
            //                let newURLString = tab.webView.url?.absoluteString
            //                tab.addressText = newURLString ?? tab.addressText
            //
            //                // Mark that we navigated away from the initial blank once URL is not about:blank
            //                if tab.hasNavigatedAwayFromInitialBlank == false,
            //                   let newURLString,
            //                   newURLString != "about:blank" {
            //                    tab.hasNavigatedAwayFromInitialBlank = true
            
            // Safe KVO using observation tokens (auto-invalidated on deinit)
            titleObservation = tab.webView.observe(\.title, options: [.new]) { [weak tab] _, _ in
                guard let tab else { return }
                DispatchQueue.main.async {
                    let t = tab.webView.title?.trimmingCharacters(in: .whitespacesAndNewlines)
                    tab.title = (t?.isEmpty == false) ? t! : "New Tab"
                }
            }
            
            
            urlObservation = tab.webView.observe(\.url, options: [.new]) { [weak tab] _, _ in
                guard let tab else { return }
                DispatchQueue.main.async {
                    let newURLString = tab.webView.url?.absoluteString
                    tab.addressText = newURLString ?? tab.addressText
                    
                    // Mark that we navigated away from the initial blank once URL is not about:blank
                    if tab.hasNavigatedAwayFromInitialBlank == false,
                       let newURLString,
                       newURLString != "about:blank" {
                        tab.hasNavigatedAwayFromInitialBlank = true
                    }
                }
            }
        }
        
        // MARK: - New-tab routing rules
        
        private func isSeatGeekCheckoutURL(_ url: URL) -> Bool {
            guard let host = url.host?.lowercased() else { return false }
            // Accept both seatgeek.com and www.seatgeek.com
            guard host == "seatgeek.com" || host.hasSuffix(".seatgeek.com") else { return false }
            return url.path.lowercased().hasPrefix("/checkout")
        }
        
        private func openInSameTab(_ url: URL, webView: WKWebView) {
            // Force navigation in the current tab instead of opening a new tab/window
            webView.load(URLRequest(url: url))
        }
        
        func webView(_ webView: WKWebView,
                     decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            // Handle links that want to open in a new tab/window (target=_blank).
            if navigationAction.targetFrame == nil,
               let url = navigationAction.request.url {
                
                // ✅ SeatGeek checkout: stay in the SAME tab (avoid opening a new tab)
                if isSeatGeekCheckoutURL(url) {
                    openInSameTab(url, webView: webView)
                    decisionHandler(.cancel)
                    return
                }
                
                // Default behavior: open in a new tab in the same window
                onOpenInNewTab(url)
                decisionHandler(.cancel)
                return
            }
            decisionHandler(.allow)
        }
        
        func webView(_ webView: WKWebView,
                     createWebViewWith configuration: WKWebViewConfiguration,
                     for navigationAction: WKNavigationAction,
                     windowFeatures: WKWindowFeatures) -> WKWebView? {
            // Many sites use window.open() which lands here.
            if navigationAction.targetFrame == nil,
               let url = navigationAction.request.url {
                
                // ✅ SeatGeek checkout: stay in the SAME tab (avoid opening a new tab)
                if isSeatGeekCheckoutURL(url) {
                    openInSameTab(url, webView: webView)
                    return nil
                }
                
                // Default behavior: open in a new tab in the same window
                onOpenInNewTab(url)
            }
            return nil
        }
        
        
        deinit {
            titleObservation = nil
            urlObservation = nil
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            guard let tab else { return }
            tab.isLoading = true
            tab.canGoBack = webView.canGoBack
            tab.canGoForward = webView.canGoForward
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            guard let tab else { return }
            tab.isLoading = false
            tab.canGoBack = webView.canGoBack
            tab.canGoForward = webView.canGoForward
            tab.addressText = webView.url?.absoluteString ?? tab.addressText
            
            // Fetch favicon (best-effort) using the page's <link rel="icon">.
            let js = """
            (function() {
              const rels = ["icon", "shortcut icon", "apple-touch-icon", "apple-touch-icon-precomposed"];
              for (const r of rels) {
                const el = document.querySelector(`link[rel='${r}']`) || document.querySelector(`link[rel~='${r}']`);
                if (el && el.href) return el.href;
              }
              return null;
            })();
            """
            
            webView.evaluateJavaScript(js) { [weak tab] result, _ in
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
                    } catch {
                        // ignore favicon failures
                    }
                }
            }
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            guard let tab else { return }
            tab.isLoading = false
            tab.canGoBack = webView.canGoBack
            tab.canGoForward = webView.canGoForward
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            guard let tab else { return }
            tab.isLoading = false
            tab.canGoBack = webView.canGoBack
            tab.canGoForward = webView.canGoForward
            tab.addressText = webView.url?.absoluteString ?? tab.addressText
        }
        
        
        func webView(_ webView: WKWebView,
                     didReceive challenge: URLAuthenticationChallenge,
                     completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
            // Some proxies require an explicit auth challenge response from WebKit.
            // If we don't answer, navigation can appear to "load forever".
            guard let tab else {
                completionHandler(.performDefaultHandling, nil)
                return
            }
            
            // Proxy auth challenges usually come through with a proxyType (HTTP/HTTPS).
            if let proxyType = challenge.protectionSpace.proxyType,
               proxyType == kCFProxyTypeHTTP as String || proxyType == kCFProxyTypeHTTPS as String {
                guard let proxy = tab.authProxy else {
                    completionHandler(.performDefaultHandling, nil)
                    return
                }
                
                let credential = URLCredential(user: proxy.username,
                                               password: proxy.password,
                                               persistence: .forSession)
                completionHandler(.useCredential, credential)
                return
            }
            
            // Server/basic auth (not proxy) — let the system handle unless you want to customize.
            completionHandler(.performDefaultHandling, nil)
        }
    }
}
