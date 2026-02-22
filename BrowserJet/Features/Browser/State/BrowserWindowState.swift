//
//  BrowserWindowState.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 16/02/2026.
//


import Foundation
import WebKit

@MainActor
final class BrowserWindowState: ObservableObject {
    let proxyType: ProxyType
    let userAgent: String?
    private let isolationMode: SessionIsolationMode
    private let sessionManager: SessionManager
    let proxies: [AuthProxy]
    private let proxyPool = ProxyPoolService()
    private let rotation: ProxyRotationType = .linear // for now; later derive from launcher
    private let initialURL: URL
    
    // For `.perWindow`: share a single store and a single proxy (if needed)
    private lazy var perWindowProxy: AuthProxy? = {
        proxyType.resolveAuthProxy(slot: 0, proxies: proxies)
    }()

    private lazy var perWindowDataStore: WKWebsiteDataStore = {
        makeNewDataStore(proxy: perWindowProxy)
    }()

    @Published var tabs: [TabModel] = []
    @Published var selectedTabID: UUID?

    init(
        proxyType: ProxyType,
        isolationMode: SessionIsolationMode,
        proxies: [AuthProxy],
        userAgent: String?,
        sessionManager: SessionManager,
        initialURL: URL,
        initialTabCount: Int
    ) {
        self.proxyType = proxyType
        self.isolationMode = isolationMode
        self.proxies = proxies
        self.userAgent = userAgent
        self.sessionManager = sessionManager
        self.initialURL = initialURL
        
        if !proxyType.isLocal {
                proxyPool.configure(provider: StaticAuthProxyProvider(proxies: proxies), rotation: rotation)
            }

        addTab(url: initialURL)
        
        let count = max(1, initialTabCount)
        for _ in 0..<count {
            addTab(url: initialURL)
        }
    }

    private func makeNewDataStore(proxy: AuthProxy?) -> WKWebsiteDataStore {
        let store = WKWebsiteDataStore(forIdentifier: UUID())

        // NOTE: only apply proxy when we actually have one.
        if let proxy {
            store.proxyConfigurations = [ProxyConfigurationFactory.makeProxyConfiguration(proxy)]
        }
        return store
    }

    private func dataStoreForNewTab(proxy: AuthProxy?) -> WKWebsiteDataStore {
        switch isolationMode {
        case .perWindow:
            return perWindowDataStore
        case .perTab:
            return makeNewDataStore(proxy: proxy)
        }
    }

    func addTab(url: URL? = nil) {
        // swiftlint:disable:next force_unwrapping
        let tabURL = url ?? URL(string: "about:blank")!
        guard let slot = sessionManager.acquireSessionSlot() else { return }

        let tabProxy: AuthProxy?
        switch isolationMode {
        case .perWindow:
            tabProxy = perWindowProxy
        case .perTab:
            tabProxy = proxyType.isLocal ? nil : proxyPool.getProxy(for: slot)
        }

        // Log VPN details for the tab
        if let proxy = tabProxy {
            AppLogger.info(
                "Tab assigned VPN - Slot: \(slot), IP: \(proxy.host), Port: \(proxy.port), Username: \(proxy.username), Password: \(proxy.password)"
            )
        } else {
            AppLogger.info("Tab assigned - Slot: \(slot), Proxy: None (Local connection)")
        }

        let store = dataStoreForNewTab(proxy: tabProxy)

        let tab = TabModel(
            sessionSlot: slot,
            startURL: tabURL,
            dataStore: store,
            proxyType: proxyType,
            authProxy: tabProxy,
            userAgent: userAgent
        ) { [weak self] newURL in
            self?.addTab(url: newURL)
        }

        tabs.append(tab)
        selectedTabID = tab.id
    }

    func closeTab(_ tabID: UUID) {
        guard let index = tabs.firstIndex(where: { $0.id == tabID }) else { return }
        let slot = tabs[index].sessionSlot
        tabs.remove(at: index)
        sessionManager.releaseSessionSlot(slot)

        if !proxyType.isLocal {
            proxyPool.removeProxy(for: slot)
        }

        if tabs.isEmpty {
            addTab(url: initialURL)
        } else {
            selectedTabID = tabs.last?.id
        }
    }

    func select(_ tab: TabModel) {
        selectedTabID = tab.id
    }

    var selectedTab: TabModel? {
        tabs.first { $0.id == selectedTabID }
    }

    /// For UI label: Local / On VPN / Premium / Custom
    var connectionStatusTitle: String {
        proxyType.statusTitle
    }
    
    @MainActor
    private func burnProxyAndReload(tabID: UUID) {
        guard !proxyType.isLocal else {
            AppLogger.info("Burn ignored: Local mode")
            return
        }
        guard isolationMode == .perTab else {
            AppLogger.info("Burn ignored: not perTab isolation mode")
            return
        }
        guard let tab = tabs.first(where: { $0.id == tabID }) else { return }

        let slot = tab.sessionSlot
        guard let newProxy = proxyPool.burnProxy(for: slot) else {
            AppLogger.warning("Burn failed: no proxies available")
            return
        }

        // Capture the current URL before replacing the web view
        let currentURL = tab.webView.url
            ?? URL(string: tab.addressText)
            ?? initialURL

        // Build a fresh data store with the new proxy baked in
        let newStore = makeNewDataStore(proxy: newProxy)

        // Update the in-memory credential (for auth challenge handler)
        tab.updateAuthProxy(newProxy)

        // Replace the WKWebView entirely — this is the real burn
        tab.replaceWebView(newStore: newStore, url: currentURL, userAgent: userAgent)

        AppLogger.info("Burned proxy for slot \(slot). New proxy: \(newProxy.host):\(newProxy.port). URL: \(currentURL.absoluteString)")
    }

    @MainActor
    func burnProxyAndReloadSelectedTab() {
        guard let id = selectedTabID else { return }
        burnProxyAndReload(tabID: id)
    }
}
