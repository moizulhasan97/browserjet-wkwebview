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
        let webView = tab.webView
        webView.uiDelegate = context.coordinator

        // If a burn just happened, pendingURL holds the URL to load. We defer
        // by one run-loop tick so AppKit has finished sizing the view and adding
        // it to the window before WebKit starts rendering — this prevents the
        // "content only appears after switching tabs" stall.
        if let url = tab.pendingURL {
            tab.pendingURL = nil
            DispatchQueue.main.async {
                webView.load(URLRequest(url: url))
            }
        } else if shouldReloadVisibleTab(webView: webView, tab: tab) {
            DispatchQueue.main.async {
                if let resolvedURL = AddressBarURLResolver.resolve(tab.addressText) {
                    webView.load(URLRequest(url: resolvedURL))
                }
            }
        }

        return webView
    }

    private func shouldReloadVisibleTab(webView: WKWebView, tab: TabModel) -> Bool {
          let text = tab.addressText.trimmingCharacters(in: .whitespacesAndNewlines)
          guard !text.isEmpty, text != "about:blank" else { return false }
          // Init load ran before the view was in the window; retry once attached.
          guard webView.url == nil else { return false }
          return true
      }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        // Update coordinator's tab reference when tab changes
        context.coordinator.updateTab(tab)
        // Always point the UI delegate at the live web view
        // (nsView == tab.webView in normal flow; after a burn SwiftUI
        //  recreates the container via .id(tab.webViewID) so makeNSView
        //  is called instead, but this guard keeps things consistent.)
        tab.webView.uiDelegate = context.coordinator
    }

    final class Coordinator: NSObject, WKUIDelegate {
        private weak var tab: TabModel?
        private let onOpenInNewTab: (URL) -> Void

        init(tab: TabModel, onOpenInNewTab: @escaping (URL) -> Void) {
            self.tab = tab
            self.onOpenInNewTab = onOpenInNewTab
            super.init()
            // Update tab's callback in case it wasn't set during initialization
            tab.setOnOpenInNewTab(onOpenInNewTab)
        }

        func updateTab(_ newTab: TabModel) {
            // Update tab reference when tab changes
            self.tab = newTab
            // Update the callback for the new tab
            newTab.setOnOpenInNewTab(onOpenInNewTab)
        }

        // MARK: - UI Delegate (for window.open())

        func webView(
            _ webView: WKWebView,
            createWebViewWith configuration: WKWebViewConfiguration,
            for navigationAction: WKNavigationAction,
            windowFeatures: WKWindowFeatures
        ) -> WKWebView? {
            // Many sites use window.open() which lands here
            if navigationAction.targetFrame == nil,
                let url = navigationAction.request.url {
                // SeatGeek checkout: stay in the SAME tab
                if isSeatGeekCheckoutURL(url) {
                    openInSameTab(url, webView: webView)
                    return nil
                }

                // Default: open in a new tab
                onOpenInNewTab(url)
            }
            return nil
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
}
