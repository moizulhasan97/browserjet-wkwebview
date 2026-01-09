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
//@main
//struct browserjet_wkwebviewApp: App {
//    var body: some Scene {
//        WindowGroup {
//            ContentView()
//        }
//    }
//}

// MARK: - App Window State
@MainActor
final class AppWindowState: ObservableObject {
    @Published var isProxy2WindowOpen: Bool = false
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
    let proxy: AuthProxy
    
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
    
    init(startURL: URL, proxy: AuthProxy) {
        self.proxy = proxy
        self.startedAsAboutBlank = (startURL.absoluteString == "about:blank")
        self.hasNavigatedAwayFromInitialBlank = !self.startedAsAboutBlank

        let dataStore = WKWebsiteDataStore(forIdentifier: UUID())
        dataStore.proxyConfigurations = [makeProxyConfiguration(proxy)]

        let config = WKWebViewConfiguration()
        config.websiteDataStore = dataStore

        self.webView = WKWebView(frame: .zero, configuration: config)

        load(startURL)
    }
    
    func load(_ url: URL) {
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

    // ✅ Window-level proxy only
    let proxy: AuthProxy

    @Published var tabs: [TabModel] = []
    @Published var selectedTabID: UUID?

    init(proxy: AuthProxy) {
        self.proxy = proxy
        addTab() // default 1 tab on launch
    }

    var selectedTab: TabModel? {
        tabs.first(where: { $0.id == selectedTabID })
    }

    func addTab(url: URL = URL(string: "about:blank")!) {
        // ✅ max 5 tabs per window (as per your last requirement)
        guard tabs.count < 5 else { return }

        let tab = TabModel(startURL: url, proxy: proxy)
        tabs.append(tab)
        selectedTabID = tab.id
    }

    func closeTab(_ id: UUID) {
        tabs.removeAll { $0.id == id }
        if selectedTabID == id {
            selectedTabID = tabs.last?.id
        }
        if tabs.isEmpty {
            addTab()
        }
    }

    func select(_ tab: TabModel) {
        selectedTabID = tab.id
    }
}

// MARK: - WebView Wrapper

struct WebViewContainer: NSViewRepresentable {
    @ObservedObject var tab: TabModel
    
    func makeCoordinator() -> Coordinator {
        Coordinator(tab: tab)
    }
    
    func makeNSView(context: Context) -> WKWebView {
        tab.webView.navigationDelegate = context.coordinator
        //tab.webView.addObserver(context.coordinator, forKeyPath: "title", options: .new, context: nil)
        //tab.webView.addObserver(context.coordinator, forKeyPath: "URL", options: .new, context: nil)
        return tab.webView
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {
        // no-op
    }
    
    final class Coordinator: NSObject, WKNavigationDelegate {
        private weak var tab: TabModel?
        private var titleObservation: NSKeyValueObservation?
        private var urlObservation: NSKeyValueObservation?

        init(tab: TabModel) {
            self.tab = tab
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
    
    @EnvironmentObject private var appWindowState: AppWindowState
    @Environment(\.openWindow) private var openWindow
    private var newTabProxy: AuthProxy? {
        state.selectedTab?.proxy
    }
    var body: some View {
        VStack(spacing: 0) {
            // Tabs row + (optional) New Window + plus + proxy badge
            HStack(spacing: 10) {
                Text("Proxy: \(state.proxy.display)")
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
                
                // ✅ New Window button (only in Proxy 1 window)
                if showsNewWindowButton {
                    Button {
                        openWindow(id: "proxy2")
                        appWindowState.isProxy2WindowOpen = true
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
                        .background(appWindowState.isProxy2WindowOpen ? AppTheme.stroke.opacity(0.4) : AppTheme.stroke)
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                    .disabled(appWindowState.isProxy2WindowOpen)
                    .opacity(appWindowState.isProxy2WindowOpen ? 0.6 : 1)
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
            
            // Address bar + content
            if let tab = state.selectedTab {
                AddressBar(tab: tab)
                WebViewContainer(tab: tab)
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

    private let proxy1 = AuthProxy.parse("151.145.144.63:9143:eagaO:jOJFcfzM") // Window 1
    private let proxy2 = AuthProxy.parse("151.145.144.62:9142:eagaO:jOJFcfzM") // Window 2

    @StateObject private var appWindowState = AppWindowState()

    var body: some Scene {

        // Window 1 — opens on launch
        WindowGroup("Proxy 1 Browser") {
            BrowserWindowView(
                state: BrowserWindowState(proxy: proxy1),
                showsNewWindowButton: true
            )
            .environmentObject(appWindowState)
        }

        // Window 2 — opens ONLY when requested
        WindowGroup("Proxy 2 Browser", id: "proxy2") {
            BrowserWindowView(
                state: BrowserWindowState(proxy: proxy2),
                showsNewWindowButton: false
            )
            .environmentObject(appWindowState)
            .background(
                WindowCloseObserver {
                    appWindowState.isProxy2WindowOpen = false
                }
            )
            .onAppear {
                appWindowState.isProxy2WindowOpen = true
            }
        }
    }
}

//private struct RootWindowView: View {
//    let proxy: AuthProxy
//    let userAgent: String
//
//    @Binding var didAutoOpenAllWindows: Bool
//
//    @Environment(\.openWindow) private var openWindow
//    @EnvironmentObject private var appWindowState: AppWindowState
//
//    var body: some View {
//        BrowserWindowView(
//            state: BrowserWindowState(proxy: proxy, userAgent: userAgent),
//            showsNewWindowButton: false
//        )
//        .onAppear { appWindowState.setOpen(0, true) }
//        .background(
//            WindowCloseObserver { appWindowState.setOpen(0, false) }
//        )
//        .task {
//            guard !didAutoOpenAllWindows else { return }
//            didAutoOpenAllWindows = true
//
//            // Open windows 2..10
//            openWindow(id: "w2");  appWindowState.setOpen(1, true)
//            openWindow(id: "w3");  appWindowState.setOpen(2, true)
//            openWindow(id: "w4");  appWindowState.setOpen(3, true)
//            openWindow(id: "w5");  appWindowState.setOpen(4, true)
//            openWindow(id: "w6");  appWindowState.setOpen(5, true)
//            openWindow(id: "w7");  appWindowState.setOpen(6, true)
//            openWindow(id: "w8");  appWindowState.setOpen(7, true)
//            openWindow(id: "w9");  appWindowState.setOpen(8, true)
//            openWindow(id: "w10"); appWindowState.setOpen(9, true)
//        }
//    }
//}

