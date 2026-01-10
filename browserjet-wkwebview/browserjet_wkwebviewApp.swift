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

// MARK: - AppConfig
enum AppConfig {
    static let isUserAgentEnabled: Bool = false
    static let proxyType: ProxyType = .proxy
}

// MARK: - BrowserUserAgent
enum BrowserUserAgent: String, CaseIterable {
    case chrome116 = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.0.0 Safari/537.36"
    case chrome118 = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/118.0.0.0 Safari/537.36"
    case chrome120 = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    case chrome143 = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36"
}

// MARK: - App Window State
@MainActor
final class AppWindowState: ObservableObject {
    /// 10 window “slots”: w1...w10 (index 0...9)
    @Published private(set) var openSlots: [Bool] = Array(repeating: false, count: 10)

    func setOpen(_ slot: Int, _ isOpen: Bool) {
        guard openSlots.indices.contains(slot) else { return }
        openSlots[slot] = isOpen
    }

    var openCount: Int { openSlots.filter { $0 }.count }
    var canOpenMore: Bool { openCount < 10 }

    /// Next available slot (0...9) for opening a new window
    func nextAvailableSlot() -> Int? {
        openSlots.firstIndex(where: { !$0 })
    }

    /// The “display number” (1...N) for a given slot among currently open windows.
    /// This enables renumbering after a close (e.g. if slot 2 closes, slot 3 becomes “2”, etc.)
    func displayNumber(for slot: Int) -> Int? {
        guard openSlots.indices.contains(slot), openSlots[slot] else { return nil }
        let openIndices = openSlots.enumerated().compactMap { $0.element ? $0.offset : nil }
        guard let rank = openIndices.firstIndex(of: slot) else { return nil }
        return rank + 1
    }
}

// MARK: - NSWindow Close Observer

struct WindowCloseObserver: NSViewRepresentable {
    let onWillClose: () -> Void
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            NotificationCenter.default.addObserver(
                context.coordinator,
                selector: #selector(Coordinator.windowWillClose(_:)),
                name: NSWindow.willCloseNotification,
                object: window
            )
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onWillClose: onWillClose)
    }
    
    final class Coordinator: NSObject {
        let onWillClose: () -> Void
        init(onWillClose: @escaping () -> Void) { self.onWillClose = onWillClose }
        
        @objc func windowWillClose(_ note: Notification) {
            onWillClose()
        }
        
        deinit {
            NotificationCenter.default.removeObserver(self)
        }
    }
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
    var config = ProxyConfiguration(httpCONNECTProxy: endpoint, tlsOptions: nil)
    config.applyCredential(username: proxy.username, password: proxy.password)
    return config
}

// MARK: - Tab Model

@MainActor
final class TabModel: ObservableObject, Identifiable {
    let id = UUID()
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
    
    init(startURL: URL, proxyType: ProxyType, proxy: AuthProxy?, userAgent: String?) {
        self.proxy = proxy
        self.startedAsAboutBlank = (startURL.absoluteString == "about:blank")
        self.hasNavigatedAwayFromInitialBlank = !self.startedAsAboutBlank

        let config = WKWebViewConfiguration()

        if proxyType == .proxy, let proxy {
            let dataStore = WKWebsiteDataStore(forIdentifier: UUID())
            dataStore.proxyConfigurations = [makeProxyConfiguration(proxy)]
            config.websiteDataStore = dataStore
        } else {
            // ✅ Local = use normal internet / system networking
            config.websiteDataStore = .default()
        }

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
    let proxy: AuthProxy?
    let userAgent: String?

    @Published var tabs: [TabModel] = []
    @Published var selectedTabID: UUID?

    init(proxy: AuthProxy?, userAgent: String?) {
        self.proxyType = AppConfig.proxyType

        // ✅ If Local: ignore proxies entirely
        if AppConfig.proxyType == .local {
            self.proxy = nil
        } else {
            self.proxy = proxy
        }

        self.userAgent = userAgent
        addTab()
    }

    var selectedTab: TabModel? {
        tabs.first(where: { $0.id == selectedTabID })
    }

    func addTab(url: URL = URL(string: "about:blank")!) {
        guard tabs.count < 5 else { return }

        let tab = TabModel(
            startURL: url,
            proxyType: proxyType,
            proxy: proxy,               // nil if local, proxy if proxy-mode
            userAgent: userAgent
        )

        tabs.append(tab)
        selectedTabID = tab.id
    }

    func closeTab(_ id: UUID) {
        tabs.removeAll { $0.id == id }
        if selectedTabID == id { selectedTabID = tabs.last?.id }
        if tabs.isEmpty { addTab() }
    }

    func select(_ tab: TabModel) {
        selectedTabID = tab.id
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
        
        func webView(_ webView: WKWebView,
                     decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            // Handle links that want to open in a new tab/window (target=_blank).
            if navigationAction.targetFrame == nil,
               let url = navigationAction.request.url {
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
    let showsNewWindowButton: Bool
    let slotIndex: Int   // ✅ add this (0...9)

    @EnvironmentObject private var appWindowState: AppWindowState
    @Environment(\.openWindow) private var openWindow

    private var computedWindowTitle: String {
        if let n = appWindowState.displayNumber(for: slotIndex) {
            return "Proxy Browser \(n)"
        } else {
            // fallback (shouldn’t really happen while open)
            return "Proxy Browser"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {

                Text(
                    state.proxyType == .local
                    ? "Connection: Local"
                    : "Proxy: \(state.proxy?.display ?? "—")"
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

                // ✅ New Window button (from every window), disabled at 10
                if showsNewWindowButton {
                    let canOpenMore = appWindowState.canOpenMore
                    Button {
                        guard let next = appWindowState.nextAvailableSlot() else { return }
                        openWindow(id: "w\(next + 1)")
                        appWindowState.setOpen(next, true)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "macwindow.badge.plus")
                                .font(.system(size: 13, weight: .bold))
                            Text("New Window")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .frame(height: 30)
                        .background(canOpenMore ? AppTheme.stroke : AppTheme.stroke.opacity(0.4))
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                    .disabled(!canOpenMore)
                    .opacity(canOpenMore ? 1 : 0.6)
                }

                // ✅ Add Tab button (max 5 tabs)
                Button {
                    state.addTab()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 30, height: 30)
                        .background(AppTheme.stroke)
                        .cornerRadius(10)
                }
                .buttonStyle(.plain)
                .disabled(state.tabs.count >= 5)
                .opacity(state.tabs.count >= 5 ? 0.5 : 1)
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

        // ✅ This makes titles auto-renumber on close/open
        .background(WindowTitleSetter(title: computedWindowTitle))
    }
}

// MARK: - App Entry (two windows)

@main
struct ProxyBrowserApp: App {

    private let proxies: [AuthProxy] = [
        AuthProxy.parse("151.145.144.63:9143:eagaO:jOJFcfzM"), // w1
        AuthProxy.parse("151.145.144.62:9142:eagaO:jOJFcfzM"), // w2
        AuthProxy.parse("151.145.144.61:9141:eagaO:jOJFcfzM"), // w3
        AuthProxy.parse("151.145.156.73:12213:eagaO:jOJFcfzM"), // w4
        AuthProxy.parse("151.145.156.72:12212:eagaO:jOJFcfzM"), // w5
        AuthProxy.parse("151.145.156.71:12211:eagaO:jOJFcfzM"), // w6
        AuthProxy.parse("151.145.156.70:12210:eagaO:jOJFcfzM"), // w7
        AuthProxy.parse("151.145.156.69:12209:eagaO:jOJFcfzM"), // w8
        AuthProxy.parse("151.145.156.68:12208:eagaO:jOJFcfzM"), // w9
        AuthProxy.parse("151.145.156.67:12207:eagaO:jOJFcfzM")  // w10
    ]

    @StateObject private var appWindowState = AppWindowState()

    var body: some Scene {

        // w1 opens on launch
        WindowGroup("Proxy Browser", id: "w1") {
            BrowserWindowView(
                state: BrowserWindowState(proxy: proxies[0], userAgent: userAgentForSlot(0)),
                showsNewWindowButton: true,
                slotIndex: 0
            )
            .environmentObject(appWindowState)
            .onAppear { appWindowState.setOpen(0, true) }
            .background(WindowCloseObserver { appWindowState.setOpen(0, false) })
        }

        WindowGroup("Proxy Browser", id: "w2") {
            BrowserWindowView(
                state: BrowserWindowState(proxy: proxies[1], userAgent: userAgentForSlot(1)),
                showsNewWindowButton: true,
                slotIndex: 1
            )
            .environmentObject(appWindowState)
            .onAppear { appWindowState.setOpen(1, true) }
            .background(WindowCloseObserver { appWindowState.setOpen(1, false) })
        }

        WindowGroup("Proxy Browser", id: "w3") {
            BrowserWindowView(
                state: BrowserWindowState(proxy: proxies[2], userAgent: userAgentForSlot(2)),
                showsNewWindowButton: true,
                slotIndex: 2
            )
            .environmentObject(appWindowState)
            .onAppear { appWindowState.setOpen(2, true) }
            .background(WindowCloseObserver { appWindowState.setOpen(2, false) })
        }

        WindowGroup("Proxy Browser", id: "w4") {
            BrowserWindowView(
                state: BrowserWindowState(proxy: proxies[3], userAgent: userAgentForSlot(3)),
                showsNewWindowButton: true,
                slotIndex: 3
            )
            .environmentObject(appWindowState)
            .onAppear { appWindowState.setOpen(3, true) }
            .background(WindowCloseObserver { appWindowState.setOpen(3, false) })
        }

        WindowGroup("Proxy Browser", id: "w5") {
            BrowserWindowView(
                state: BrowserWindowState(proxy: proxies[4], userAgent: userAgentForSlot(4)),
                showsNewWindowButton: true,
                slotIndex: 4
            )
            .environmentObject(appWindowState)
            .onAppear { appWindowState.setOpen(4, true) }
            .background(WindowCloseObserver { appWindowState.setOpen(4, false) })
        }

        WindowGroup("Proxy Browser", id: "w6") {
            BrowserWindowView(
                state: BrowserWindowState(proxy: proxies[5], userAgent: userAgentForSlot(5)),
                showsNewWindowButton: true,
                slotIndex: 5
            )
            .environmentObject(appWindowState)
            .onAppear { appWindowState.setOpen(5, true) }
            .background(WindowCloseObserver { appWindowState.setOpen(5, false) })
        }

        WindowGroup("Proxy Browser", id: "w7") {
            BrowserWindowView(
                state: BrowserWindowState(proxy: proxies[6], userAgent: userAgentForSlot(6)),
                showsNewWindowButton: true,
                slotIndex: 6
            )
            .environmentObject(appWindowState)
            .onAppear { appWindowState.setOpen(6, true) }
            .background(WindowCloseObserver { appWindowState.setOpen(6, false) })
        }

        WindowGroup("Proxy Browser", id: "w8") {
            BrowserWindowView(
                state: BrowserWindowState(proxy: proxies[7], userAgent: userAgentForSlot(7)),
                showsNewWindowButton: true,
                slotIndex: 7
            )
            .environmentObject(appWindowState)
            .onAppear { appWindowState.setOpen(7, true) }
            .background(WindowCloseObserver { appWindowState.setOpen(7, false) })
        }

        WindowGroup("Proxy Browser", id: "w9") {
            BrowserWindowView(
                state: BrowserWindowState(proxy: proxies[8], userAgent: userAgentForSlot(8)),
                showsNewWindowButton: true,
                slotIndex: 8
            )
            .environmentObject(appWindowState)
            .onAppear { appWindowState.setOpen(8, true) }
            .background(WindowCloseObserver { appWindowState.setOpen(8, false) })
        }

        WindowGroup("Proxy Browser", id: "w10") {
            BrowserWindowView(
                state: BrowserWindowState(proxy: proxies[9], userAgent: userAgentForSlot(9)),
                showsNewWindowButton: true,
                slotIndex: 9
            )
            .environmentObject(appWindowState)
            .onAppear { appWindowState.setOpen(9, true) }
            .background(WindowCloseObserver { appWindowState.setOpen(9, false) })
        }
    }
    
    private func activeUserAgents() -> [String] {
        guard AppConfig.isUserAgentEnabled else { return [] }

        // Never exceed allowed windows
        let maxWindows = 10
        let allAgents = BrowserUserAgent.allCases.map { $0.rawValue }
        return Array(allAgents.prefix(maxWindows))
    }

    private func userAgentForSlot(_ slot: Int) -> String? {
        let agents = activeUserAgents()
        guard !agents.isEmpty else { return nil }

        // Round-robin assignment
        return agents[slot % agents.count]
    }
}

struct WindowTitleSetter: NSViewRepresentable {
    let title: String

    func makeNSView(context: Context) -> NSView {
        NSView(frame: .zero)
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            nsView.window?.title = title
        }
    }
}

