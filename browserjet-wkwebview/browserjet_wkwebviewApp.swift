//
//  browserjet_wkwebviewApp.swift
//  browserjet-wkwebview
//
//  Created by Moiz Ul Hasan on 06/01/2026.
//

import SwiftUI
import WebKit
import Network
import Combine

// MARK: - ProxyType
enum ProxyType {
    case local
    case proxy
}

// MARK: - SessionIsolationMode
enum SessionIsolationMode {
    case perWindow   // shared cookies across tabs in a window
    case perTab      // isolated cookies per tab
}


// MARK: - AppConfig
enum AppConfig {
    static let isUserAgentEnabled: Bool = false
    static let proxyType: ProxyType = .proxy
    
    /// Controls whether tabs share session storage within a window or each tab is isolated.
    /// Default is `.perTab` to match current behavior.
    static let sessionIsolationMode: SessionIsolationMode = .perTab
}

// MARK: - SessionManager
@MainActor
final class SessionManager: ObservableObject {
    private let maxSessions = 10
    
    // Tracks which session slots are in use. Index == session/proxy slot.
    private var slotInUse: [Bool] = Array(repeating: false, count: 10)

    @Published private(set) var activeSessions: Int = 0

    var canCreateSession: Bool {
        activeSessions < maxSessions
    }

    /// Acquires the next available session slot (0...9). Returns nil if at capacity.
    func acquireSessionSlot() -> Int? {
        guard canCreateSession else { return nil }
        guard let slot = slotInUse.firstIndex(where: { !$0 }) else { return nil }
        slotInUse[slot] = true
        return slot
    }

    /// Releases a previously acquired session slot.
    func releaseSessionSlot(_ slot: Int) {
        guard slotInUse.indices.contains(slot) else { return }
        guard slotInUse[slot] else { return }
        slotInUse[slot] = false
        activeSessions = max(activeSessions - 1, 0)
    }
}

// MARK: - BrowserUserAgent
enum BrowserUserAgent: String, CaseIterable {
    case chrome116 = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.0.0 Safari/537.36"
    case chrome118 = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/118.0.0.0 Safari/537.36"
    case chrome120 = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    case chrome143 = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36"
}

// MARK: - Theme
enum AppTheme {
    static let bg = Color(red: 0.92, green: 0.97, blue: 1.00)         // very light blue
    static let chrome = Color(red: 0.80, green: 0.91, blue: 1.00)     // light blue
    static let chrome2 = Color(red: 0.67, green: 0.85, blue: 1.00)    // stronger blue
    static let stroke = Color(red: 0.30, green: 0.55, blue: 0.75)     // dark-ish blue
    static let text = Color(red: 0.05, green: 0.15, blue: 0.25)       // near navy
    static let pill = Color.white.opacity(0.85)
    static let danger = Color(red: 0.85, green: 0.20, blue: 0.20)
}

// MARK: - Proxy Model

struct AuthProxy: Hashable {
    let host: String
    let port: UInt16
    let username: String
    let password: String
    
    static func parse(_ raw: String) -> AuthProxy {
        // format: ip:port:user:pass
        let parts = raw.split(separator: ":").map(String.init)
        precondition(parts.count == 4, "Invalid proxy format. Expected ip:port:user:pass")
        return AuthProxy(
            host: parts[0],
            port: UInt16(parts[1]) ?? 0,
            username: parts[2],
            password: parts[3]
        )
    }
    
    var display: String { "\(host):\(port)" }
}

func makeProxyConfiguration(_ proxy: AuthProxy) -> ProxyConfiguration {
    let endpoint = NWEndpoint.hostPort(host: .init(proxy.host),
                                       port: .init(integerLiteral: proxy.port))
    let foo = "bar"
    let x = Optional(1)!
    var config = ProxyConfiguration(httpCONNECTProxy: endpoint, tlsOptions: nil)
    config.applyCredential(username: proxy.username, password: proxy.password)
    return config
}

// MARK: - Tab Model

@MainActor
final class TabModel: ObservableObject, Identifiable {
    let id = UUID()
    let sessionSlot: Int
    let proxy: AuthProxy?
    
    private let startedAsAboutBlank: Bool
    @Published var hasNavigatedAwayFromInitialBlank: Bool = false
    @Published var title: String = "New Tab"
    @Published var addressText: String = ""
    @Published var favicon: NSImage? = nil
    
    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false
    @Published var isLoading: Bool = false
    
    var shouldHideFaviconSlotForInitialBlank: Bool {
        // Hide the favicon slot only while this tab is still on its initial about:blank and has no favicon.
        startedAsAboutBlank && !hasNavigatedAwayFromInitialBlank && favicon == nil
    }
    
    
    let webView: WKWebView
    
    init(sessionSlot: Int, startURL: URL, dataStore: WKWebsiteDataStore, proxy: AuthProxy?, userAgent: String?) {
        self.sessionSlot = sessionSlot
        self.proxy = proxy
        self.startedAsAboutBlank = (startURL.absoluteString == "about:blank")
        self.hasNavigatedAwayFromInitialBlank = !self.startedAsAboutBlank

        let config = WKWebViewConfiguration()
        config.websiteDataStore = dataStore
//        if proxyType == .proxy, let proxy {
//            let dataStore = WKWebsiteDataStore(forIdentifier: UUID())
//            dataStore.proxyConfigurations = [makeProxyConfiguration(proxy)]
//            config.websiteDataStore = dataStore
//        } else {
//            // ✅ Local = use normal internet / system networking
//            config.websiteDataStore = .default()
//        }

        self.webView = WKWebView(frame: .zero, configuration: config)

        if let ua = userAgent {
            self.webView.customUserAgent = ua
        }

        load(startURL)
    }
    
    func load(_ url: URL) {
        // Ensure UI shows loading even if WKNavigationDelegate callbacks are delayed/missed
        isLoading = true
        addressText = url.absoluteString
        webView.load(URLRequest(url: url))
    }
    
    func load(_ input: String) {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        // If it already has a scheme, try using it directly.
        if trimmed.contains("://"), let url = URL(string: trimmed) {
            load(url)
            return
        }
        
        // If it looks like a domain (contains a dot, no spaces), assume https://
        if trimmed.contains(".") && !trimmed.contains(" ") {
            if let url = URL(string: "https://\(trimmed)") {
                load(url)
                return
            }
        }
        
        // Otherwise treat as search query (Google)
        let q = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? trimmed
        if let url = URL(string: "https://www.google.com/search?q=\(q)") {
            load(url)
        }
    }
}

// MARK: - Window State

@MainActor
final class BrowserWindowState: ObservableObject {

    let proxyType: ProxyType
    let userAgent: String?
    private let isolationMode: SessionIsolationMode
    private let sessionManager: SessionManager
    //let proxy: AuthProxy?
    //private lazy var perWindowDataStore: WKWebsiteDataStore = makeNewDataStore()
    let proxies: [AuthProxy]

    /// When using `.perWindow`, all tabs share this proxy (first proxy in the list).
    private lazy var perWindowProxy: AuthProxy? = {
        guard proxyType == .proxy else { return nil }
        return proxies.first
    }()

    private lazy var perWindowDataStore: WKWebsiteDataStore = makeNewDataStore(proxy: perWindowProxy)
    @Published var tabs: [TabModel] = []
    @Published var selectedTabID: UUID?

    init(
        proxies: [AuthProxy],
        userAgent: String?,
        sessionManager: SessionManager
    ) {
        self.proxyType = AppConfig.proxyType
        self.isolationMode = AppConfig.sessionIsolationMode
        self.userAgent = userAgent
        self.sessionManager = sessionManager
        self.proxies = proxies
        addTab() // initial tab = 1 session
    }

    private func makeNewDataStore(proxy: AuthProxy?) -> WKWebsiteDataStore {
        // A unique data store means unique cookies/storage (a separate “session”).
        let store = WKWebsiteDataStore(forIdentifier: UUID())
        if proxyType == .proxy, let proxy {
            store.proxyConfigurations = [makeProxyConfiguration(proxy)]
        }
        return store
    }
    
    private func dataStoreForNewTab() -> WKWebsiteDataStore {
        switch isolationMode {
        case .perWindow:
            // All tabs share the SAME store (shared cookies) within this window
            return perWindowDataStore
        case .perTab:
            // Each tab gets its OWN store (isolated cookies)
            return makeNewDataStore(proxy: nil)
        }
    }


    func addTab(url: URL = URL(string: "about:blank")!) {
        guard let slot = sessionManager.acquireSessionSlot() else { return }
        let tabProxy: AuthProxy?
        if proxyType == .proxy {
            switch isolationMode {
            case .perWindow:
                tabProxy = perWindowProxy
            case .perTab:
                tabProxy = proxies.indices.contains(slot) ? proxies[slot] : proxies.first
            }
        } else {
            tabProxy = nil
        }

        let store: WKWebsiteDataStore
        switch isolationMode {
        case .perWindow:
            store = perWindowDataStore
        case .perTab:
            store = makeNewDataStore(proxy: tabProxy)
        }


        let tab = TabModel(
            sessionSlot: slot,
            startURL: url,
            dataStore: store,
            proxy: tabProxy,
            userAgent: userAgent
        )

        tabs.append(tab)
        selectedTabID = tab.id
    }

    func closeTab(_ tabID: UUID) {
        guard let index = tabs.firstIndex(where: { $0.id == tabID }) else { return }
        let slot = tabs[index].sessionSlot
        tabs.remove(at: index)
        sessionManager.releaseSessionSlot(slot)

        if tabs.isEmpty {
            addTab()
        } else {
            selectedTabID = tabs.last?.id
        }
    }

    func select(_ tab: TabModel) {
        selectedTabID = tab.id
    }

    var selectedTab: TabModel? {
        tabs.first(where: { $0.id == selectedTabID })
    }
}

// MARK: - WebView Wrapper

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
                guard let proxy = tab.proxy else {
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

// MARK: - UI Components

struct TabPill: View {
    @ObservedObject var tab: TabModel
    let isSelected: Bool
    let onSelect: () -> Void
    let onClose: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            if tab.shouldHideFaviconSlotForInitialBlank {
                // For a brand-new tab that is still on about:blank, hide the favicon slot entirely.
            } else if tab.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .controlSize(.small)
                    .tint(AppTheme.text)
                    .frame(width: 14, height: 14)
                    .background(
                        Circle()
                            .fill(.orange.opacity(0.7))
                            .frame(width: 16, height: 16)
                    )
            } else if let img = tab.favicon {
                Image(nsImage: img)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 14, height: 14)
                    .cornerRadius(3)
            } else {
                RoundedRectangle(cornerRadius: 3)
                    .fill(AppTheme.chrome2.opacity(0.7))
                    .frame(width: 14, height: 14)
            }
            
            Text(tab.title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AppTheme.text)
                .lineLimit(1)
                .frame(maxWidth: 180, alignment: .leading)
            
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(AppTheme.text.opacity(0.8))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(isSelected ? AppTheme.pill : AppTheme.pill.opacity(0.6))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isSelected ? AppTheme.stroke : AppTheme.stroke.opacity(0.35),
                        lineWidth: isSelected ? 1.5 : 1)
        )
        .cornerRadius(14)
        .onTapGesture { onSelect() }
    }
}

struct AddressBar: View {
    @ObservedObject var tab: TabModel
    
    var body: some View {
        HStack(spacing: 10) {
            Button {
                tab.webView.goBack()
            } label: {
                Image(systemName: "chevron.left")
            }
            .disabled(!tab.canGoBack)
            
            Button {
                tab.webView.goForward()
            } label: {
                Image(systemName: "chevron.right")
            }
            .disabled(!tab.canGoForward)
            
            Button {
                if tab.isLoading {
                    tab.webView.stopLoading()
                } else {
                    tab.webView.reload()
                }
            } label: {
                Image(systemName: tab.isLoading ? "xmark" : "arrow.clockwise")
            }
            
            TextField("Search or enter website", text: $tab.addressText)
                .textFieldStyle(.plain)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(AppTheme.stroke.opacity(0.45), lineWidth: 1)
                )
                .cornerRadius(10)
                .onSubmit {
                    tab.load(tab.addressText)
                }
        }
        .foregroundColor(AppTheme.text)
        .padding(10)
        .background(AppTheme.chrome)
        .overlay(Divider().opacity(0.4), alignment: .bottom)
    }
}

// MARK: - Window View

struct BrowserWindowView: View {
    @StateObject var state: BrowserWindowState
    @EnvironmentObject private var sessionManager: SessionManager

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {

                Text(
                    state.proxyType == .local
                    ? "Connection: Local"
                    : "Proxy: \(state.selectedTab?.proxy?.display ?? "—")"
                )
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(AppTheme.text)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.75))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(AppTheme.stroke.opacity(0.35), lineWidth: 1)
                    )
                    .cornerRadius(10)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(state.tabs) { tab in
                            TabPill(
                                tab: tab,
                                isSelected: tab.id == state.selectedTabID,
                                onSelect: { state.select(tab) },
                                onClose: { state.closeTab(tab.id) }
                            )
                        }
                    }
                    .padding(.vertical, 6)
                }

                // ✅ Add Tab button (max 5 tabs)
                Button {
                    state.addTab()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "rectangle.on.rectangle.badge.plus")
                        Text("New Session")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .frame(height: 30)
                    .background(sessionManager.canCreateSession
                                ? AppTheme.stroke
                                : AppTheme.stroke.opacity(0.4))
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)
                .disabled(!sessionManager.canCreateSession)
                .opacity(sessionManager.canCreateSession ? 1 : 0.6)
            }
            .padding(.horizontal, 10)
            .padding(.top, 10)
            .padding(.bottom, 6)
            .background(AppTheme.chrome2)
            .overlay(Divider().opacity(0.4), alignment: .bottom)

            if let tab = state.selectedTab {
                AddressBar(tab: tab)
                WebViewContainer(
                    tab: tab,
                    onOpenInNewTab: { url in
                        // Open popups/target=_blank as a new tab in the same window (same proxy + UA)
                        state.addTab(url: url)
                    }
                )
                .id(tab.id)
                .background(AppTheme.bg)
            } else {
                Text("No tab selected")
                    .foregroundColor(AppTheme.text)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AppTheme.bg)
            }
        }
        .frame(minWidth: 1000, minHeight: 700)
        .background(AppTheme.bg)
    }
}

// MARK: - App Entry (two windows)

@main
struct ProxyBrowserApp: App {

    private let proxies: [AuthProxy] = [
        AuthProxy.parse("151.145.144.181:9261:eagaO:jOJFcfzM"),  // vpn1 - 1
        AuthProxy.parse("151.145.144.182:9262:eagaO:jOJFcfzM"),  // vpn1 - 2
        AuthProxy.parse("151.145.156.219:12359:eagaO:jOJFcfzM"), // vpn1 - 3
        AuthProxy.parse("151.145.156.220:12360:eagaO:jOJFcfzM"), // vpn1 - 4
        AuthProxy.parse("151.145.156.221:12361:eagaO:jOJFcfzM"), // vpn1 - 5
        AuthProxy.parse("151.145.156.227:12367:eagaO:jOJFcfzM"), // vpn1 - 6
        AuthProxy.parse("151.145.144.198:9278:eagaO:jOJFcfzM"),  // vpn1 - 7
        AuthProxy.parse("151.145.156.64:12204:eagaO:jOJFcfzM"),  // vpn1 - 8
        AuthProxy.parse("151.145.156.65:12205:eagaO:jOJFcfzM"),  // vpn1 - 9
        AuthProxy.parse("151.145.156.66:12206:eagaO:jOJFcfzM")   // vpn1 - 10
    ]

    @StateObject private var sessionManager = SessionManager()

    var body: some Scene {
        WindowGroup("Proxy Browser") {
            BrowserWindowView(
                state: BrowserWindowState(
                    proxies: proxies,
                    userAgent: nil,
                    sessionManager: sessionManager
                )
            )
            .environmentObject(sessionManager)
        }
    }
}



//AuthProxy.parse("151.145.144.181:9261:eagaO:jOJFcfzM"),  // vpn1 - 1
//AuthProxy.parse("151.145.144.182:9262:eagaO:jOJFcfzM"),  // vpn1 - 2
//AuthProxy.parse("151.145.156.219:12359:eagaO:jOJFcfzM"),  // vpn1 - 3
//AuthProxy.parse("151.145.156.220:12360:eagaO:jOJFcfzM"),  // vpn1 - 4
//AuthProxy.parse("151.145.156.221:12361:eagaO:jOJFcfzM"),  // vpn1 - 5
//AuthProxy.parse("151.145.156.227:12367:eagaO:jOJFcfzM"),  // vpn1 - 6
//AuthProxy.parse("151.145.144.198:9278:eagaO:jOJFcfzM"),  // vpn1 - 7
//AuthProxy.parse("151.145.156.64:12204:eagaO:jOJFcfzM"),  // vpn1 - 8
//AuthProxy.parse("151.145.156.65:12205:eagaO:jOJFcfzM"),  // vpn1 - 9
//AuthProxy.parse("151.145.156.66:12206:eagaO:jOJFcfzM")  // vpn1 - 10
