//
//  TabModel.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 16/02/2026.
//

import Foundation
import WebKit
import AppKit

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
    @Published var favicon: NSImage? = nil
    
    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false
    @Published var isLoading: Bool = false
    
    var shouldHideFaviconSlotForInitialBlank: Bool {
        startedAsAboutBlank && !hasNavigatedAwayFromInitialBlank && favicon == nil
    }
    
    let webView: WKWebView
    
    init(
        sessionSlot: Int,
        startURL: URL,
        dataStore: WKWebsiteDataStore,
        proxyType: ProxyType,
        authProxy: AuthProxy?,
        userAgent: String?
    ) {
        self.sessionSlot = sessionSlot
        self.proxyType = proxyType
        self.authProxy = authProxy
        
        self.startedAsAboutBlank = (startURL.absoluteString == "about:blank")
        self.hasNavigatedAwayFromInitialBlank = !self.startedAsAboutBlank
        
        let config = WKWebViewConfiguration()
        config.websiteDataStore = dataStore
        
        self.webView = WKWebView(frame: .zero, configuration: config)
        
        if let ua = userAgent {
            self.webView.customUserAgent = ua
        }
        
        load(startURL)
    }
}

// MARK: - Navigation
extension TabModel {
    func load(_ url: URL) {
        isLoading = true
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
        
        let q = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? trimmed
        if let url = URL(string: "https://www.google.com/search?q=\(q)") {
            load(url)
        }
    }
}

#if DEBUG
import WebKit

extension TabModel {
    static func preview(
        addressText: String,
        title: String,
        isLoading: Bool,
        favicon: NSImage?,
        webView: WKWebView = WKWebView()
    ) -> TabModel {
        
        let store = WKWebsiteDataStore.nonPersistent()
        
        let tab = TabModel(
            sessionSlot: 0,
            startURL: URL(string: "about:blank")!,
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
