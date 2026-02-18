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

        let count = max(1, initialTabCount)
        for _ in 0..<count {
            addTab(url: initialURL)
        }
    }

    var tabItems: [BrowserTabItem] {
        tabs.map {
            BrowserTabItem(
                id: $0.id,
                title: $0.title,
                isLoading: $0.isLoading,
                favicon: $0.favicon
            )
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
        let tabURL = url ?? URL(string: "about:blank") ?? URL(string: "about:blank")!
        guard let slot = sessionManager.acquireSessionSlot() else { return }

        let tabProxy: AuthProxy?
        switch isolationMode {
        case .perWindow:
            tabProxy = perWindowProxy
        case .perTab:
            tabProxy = proxyType.resolveAuthProxy(slot: slot, proxies: proxies)
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
        tabs.first { $0.id == selectedTabID }
    }

    /// For UI label: Local / On VPN / Premium / Custom
    var connectionStatusTitle: String {
        proxyType.statusTitle
    }
}
