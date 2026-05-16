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
    
    /// When true (trial expired), only one tab is allowed; add/close tab disabled; only refresh is useful.
    let isTrialLockActive: Bool
    
    // For `.perWindow`: share a single store and a single proxy (if needed)
    private lazy var perWindowProxy: AuthProxy? = {
        proxyType.resolveAuthProxy(slot: 0, proxies: proxies)
    }()
    
    private lazy var perWindowDataStore: WKWebsiteDataStore = {
        makeNewDataStore(proxy: perWindowProxy)
    }()
    
    @Published var tabs: [TabModel] = []
    @Published var selectedTabID: UUID?
    
    /// LIFO stack of recently closed tab URLs
    @Published private(set) var closedTabsStack: [URL] = []
    private let closedTabsStackCap = 10
    
    /// Set when we close tab on the last remaining tab. The view binds this
    /// to a confirmation alert; confirming quits the app.
    @Published var showLastTabCloseConfirmation: Bool = false
    
    /// Bumped each time ⌘L is invoked. The address bar observes this token
    /// and grabs first-responder when it changes.
    @Published private(set) var focusAddressBarToken: UUID?
    
    init(
        proxyType: ProxyType,
        isolationMode: SessionIsolationMode,
        proxies: [AuthProxy],
        userAgent: String?,
        sessionManager: SessionManager,
        initialURL: URL,
        initialTabCount: Int,
        isTrialLockActive: Bool = false
    ) {
        self.proxyType = proxyType
        self.isolationMode = isolationMode
        self.proxies = proxies
        self.userAgent = userAgent
        self.sessionManager = sessionManager
        self.initialURL = initialURL
        self.isTrialLockActive = isTrialLockActive
        
        if !proxyType.isLocal {
            proxyPool.configure(provider: StaticAuthProxyProvider(proxies: proxies), rotation: rotation)
        }
        
        if isTrialLockActive {
            addInitialTabForTrialLock(url: initialURL)
        } else {
            let count = max(1, initialTabCount)
            for _ in 0..<count {
                addTab(url: initialURL)
            }
        }
    }
    
    /// When trial/license expired we need one tab; addTab returns early when isTrialLockActive, so we add it here.
    private func addInitialTabForTrialLock(url: URL) {
        guard let slot = sessionManager.acquireSessionSlot() else { return }
        let tabProxy: AuthProxy? = {
            switch isolationMode {
            case .perWindow: return perWindowProxy
            case .perTab: return proxyType.isLocal ? nil : proxyPool.getProxy(for: slot)
            }
        }()
        let store = dataStoreForNewTab(proxy: tabProxy)
        let tab = TabModel(
            sessionSlot: slot,
            startURL: url,
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
        if isTrialLockActive { return }
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
    
    /// Internal close — performs the actual removal. Use `requestCloseTab(_:)`
    /// for user-driven close so the last-tab quit confirmation is honored.
    func closeTab(_ tabID: UUID) {
        if isTrialLockActive && tabs.count <= 1 { return }
        guard let index = tabs.firstIndex(where: { $0.id == tabID }) else { return }
        let closingTab = tabs[index]
        if let url = closingTab.webView.url ?? URL(string: closingTab.addressText) {
            pushClosedTab(url: url)
        }
        let slot = closingTab.sessionSlot
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
        
        AppLogger.info(
            """
            Burned proxy for slot \(slot). \
            New proxy: \(newProxy.host):\(newProxy.port). \
            URL: \(currentURL.absoluteString)
            """
        )
    }
    
    @MainActor
    func burnProxyAndReloadSelectedTab() {
        guard let id = selectedTabID else { return }
        burnProxyAndReload(tabID: id)
    }
}

// MARK: - Shortcut-driven actions
extension BrowserWindowState {
    // MARK: Tab close with last-tab quit confirmation
    func requestCloseTab(_ tabID: UUID) {
        guard !isTrialLockActive else { return }
        if tabs.count == 1 {
            showLastTabCloseConfirmation = true
            return
        }
        closeTab(tabID)
    }
    
    func requestCloseSelectedTab() {
        guard let id = selectedTabID else { return }
        requestCloseTab(id)
    }
    
    /// Called from the confirmation alert's "Quit" action.
    func confirmQuitFromLastTabClose() {
        showLastTabCloseConfirmation = false
        AppLogger.info("Quitting app: user confirmed close of last tab")
        NSApplication.shared.terminate(nil)
    }
    
    func cancelLastTabClose() {
        showLastTabCloseConfirmation = false
    }
    
    // MARK: Reopen-closed-tab stack
    private func pushClosedTab(url: URL) {
        closedTabsStack.append(url)
        if closedTabsStack.count > closedTabsStackCap {
            closedTabsStack.removeFirst(closedTabsStack.count - closedTabsStackCap)
        }
    }
    
    func reopenLastClosedTab() {
        guard !isTrialLockActive else { return }
        guard let url = closedTabsStack.popLast() else { return }
        addTab(url: url)
    }
    
    // MARK: Tab navigation
    func selectTab(at index: Int) {
        guard tabs.indices.contains(index) else { return }
        selectedTabID = tabs[index].id
    }
    
    func selectLastTab() {
        guard let last = tabs.last else { return }
        selectedTabID = last.id
    }
    
    func selectNextTab() {
        guard tabs.count > 1,
              let id = selectedTabID,
              let current = tabs.firstIndex(where: { $0.id == id }) else { return }
        let next = (current + 1) % tabs.count
        selectedTabID = tabs[next].id
    }
    
    func selectPreviousTab() {
        guard tabs.count > 1,
              let id = selectedTabID,
              let current = tabs.firstIndex(where: { $0.id == id }) else { return }
        let prev = (current - 1 + tabs.count) % tabs.count
        selectedTabID = tabs[prev].id
    }
    
    // MARK: Per-tab navigation actions
    func reloadSelectedTab() {
        selectedTab?.webView.reload()
    }
    
    func goBackSelectedTab() {
        guard let tab = selectedTab, tab.canGoBack else { return }
        tab.webView.goBack()
    }
    
    func goForwardSelectedTab() {
        guard let tab = selectedTab, tab.canGoForward else { return }
        tab.webView.goForward()
    }
    
    func reloadAllTabs() {
        for tab in tabs {
            tab.webView.reload()
        }
        AppLogger.info("Reload all tabs: \(tabs.count)")
    }
    
    // MARK: Duplicate
    @discardableResult
    func duplicateSelectedTab(count: Int) -> Int {
        guard !isTrialLockActive else { return 0 }
        guard let selected = selectedTab else { return 0 }
        let url = selected.webView.url
        ?? URL(string: selected.addressText)
        ?? URL(string: "about:blank")
        ?? URL(fileURLWithPath: "/")
        for _ in 0..<max(1, count) {
            addTab(url: url)
        }
        AppLogger.info("Duplicated tab \(count)x -> \(url.absoluteString)")
        return count
    }
    
    // MARK: Zoom
    private static let zoomStep: CGFloat = 1.1
    private static let zoomMin: CGFloat = 0.25
    private static let zoomMax: CGFloat = 5.0
    
    func zoomInSelectedTab() {
        guard let webView = selectedTab?.webView else { return }
        let next = min(webView.pageZoom * Self.zoomStep, Self.zoomMax)
        webView.pageZoom = next
    }
    
    func zoomOutSelectedTab() {
        guard let webView = selectedTab?.webView else { return }
        let next = max(webView.pageZoom / Self.zoomStep, Self.zoomMin)
        webView.pageZoom = next
    }
    
    func zoomResetSelectedTab() {
        selectedTab?.webView.pageZoom = 1.0
    }
    
    // MARK: Address bar focus
    func requestFocusAddressBar() {
        focusAddressBarToken = UUID()
    }
    
    // MARK: Screenshot
    func takeScreenshotOfSelectedTab() {
        guard let tab = selectedTab else { return }
        let config = WKSnapshotConfiguration()
        tab.webView.takeSnapshot(with: config) { image, error in
            if let error {
                AppLogger.error("Screenshot failed: \(error.localizedDescription)")
                return
            }
            guard let image else {
                AppLogger.error("Screenshot failed: no image")
                return
            }
            guard let tiff = image.tiffRepresentation,
                  let rep = NSBitmapImageRep(data: tiff),
                  let png = rep.representation(using: .png, properties: [:]) else {
                AppLogger.error("Screenshot failed: could not encode PNG")
                return
            }
            let fileName = "BrowserJet-\(Int(Date().timeIntervalSince1970)).png"
            guard let desktop = FileManager.default.urls(
                for: .desktopDirectory, in: .userDomainMask
            ).first else {
                AppLogger.error("Screenshot failed: no Desktop directory")
                return
            }
            let url = desktop.appendingPathComponent(fileName)
            do {
                try png.write(to: url)
                AppLogger.info("Screenshot saved: \(url.path)")
            } catch {
                AppLogger.error("Screenshot save failed: \(error.localizedDescription)")
            }
        }
    }
}
