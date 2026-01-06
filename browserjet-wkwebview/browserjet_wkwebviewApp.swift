//
//  browserjet_wkwebviewApp.swift
//  browserjet-wkwebview
//
//  Created by Moiz Ul Hasan on 06/01/2026.
//

import SwiftUI
import Combine
import WebKit
@main
struct browserjet_wkwebviewApp: App {
    var body: some Scene {
           WindowGroup {
               BrowserRootView()
                   .frame(minWidth: 1100, minHeight: 720)
           }
           .windowStyle(.automatic)
       }
}

struct BrowserRootView: View {
    @StateObject private var store = BrowserStore()

    var body: some View {
        ZStack {
            // Subtle background
            LinearGradient(
                colors: [
                    Color(NSColor.windowBackgroundColor).opacity(0.9),
                    Color.black.opacity(0.06)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 10) {
                // Tabs bar
                TabsBar(
                    tabs: store.tabs,
                    selectedID: store.selectedTabID,
                    onSelect: { store.select($0) },
                    onNewTab: { store.newTab() },
                    onClose: { store.closeTab($0) }
                )
                .padding(.horizontal, 14)
                .padding(.top, 12)

                // Toolbar
                if let selected = store.selectedTab {
                    BrowserToolbar(
                        addressText: Binding(
                            get: { selected.addressText },
                            set: { store.setAddressText($0) }
                        ),
                        canGoBack: selected.canGoBack,
                        canGoForward: selected.canGoForward,
                        onBack: { store.goBack() },
                        onForward: { store.goForward() },
                        onReload: { store.reload() },
                        onStop: { store.stopLoading() },
                        isLoading: selected.isLoading,
                        onSubmitAddress: { store.loadAddressOrSearch() }
                    )
                    .padding(.horizontal, 14)
                }

                // WebView
                ZStack {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color(NSColor.controlBackgroundColor).opacity(0.7))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.12), radius: 12, y: 6)

                    if let selected = store.selectedTab {
                        WebViewContainer(tab: selected)
                            .id(selected.id)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                            .padding(1)
                    } else {
                        VStack(spacing: 10) {
                            Image(systemName: "globe")
                                .font(.system(size: 44, weight: .semibold))
                                .opacity(0.7)
                            Text("No Tabs")
                                .font(.title2.weight(.semibold))
                                .opacity(0.8)
                            Button("New Tab") { store.newTab() }
                                .buttonStyle(.borderedProminent)
                        }
                        .padding()
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
            }
        }
        .environmentObject(store)
        .onAppear {
            if store.tabs.isEmpty { store.newTab() }
        }
    }
}

@MainActor
final class BrowserStore: ObservableObject {
    @Published var tabs: [BrowserTab] = []
    @Published var selectedTabID: UUID?

    var selectedTab: BrowserTab? {
        guard let id = selectedTabID else { return nil }
        return tabs.first(where: { $0.id == id })
    }

    func newTab(initialURL: String = "about:blank") {
        let tab = BrowserTab.makeIsolated(initialURL: initialURL)
        tabs.append(tab)
        selectedTabID = tab.id
    }

    func closeTab(_ id: UUID) {
        guard let idx = tabs.firstIndex(where: { $0.id == id }) else { return }
        let wasSelected = (selectedTabID == id)

        tabs.remove(at: idx)

        if tabs.isEmpty {
            selectedTabID = nil
        } else if wasSelected {
            let newIndex = min(idx, tabs.count - 1)
            selectedTabID = tabs[newIndex].id
        }
    }

    func select(_ id: UUID) { selectedTabID = id }

    // Toolbar actions
    func goBack() { selectedTab?.webView.goBack() }
    func goForward() { selectedTab?.webView.goForward() }
    func reload() { selectedTab?.webView.reload() }
    func stopLoading() { selectedTab?.webView.stopLoading() }

    func setAddressText(_ text: String) {
        guard let id = selectedTabID,
              let idx = tabs.firstIndex(where: { $0.id == id }) else { return }
        tabs[idx].addressText = text
    }

    func loadAddressOrSearch() {
        guard let id = selectedTabID,
              let idx = tabs.firstIndex(where: { $0.id == id }) else { return }

        let raw = tabs[idx].addressText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else { return }

        let urlToLoad: URL?
        if raw.contains(" ") || (!raw.contains(".") && !raw.contains(":")) {
            // Search
            let q = raw.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? raw
            urlToLoad = URL(string: "https://www.google.com/search?q=\(q)")
        } else {
            // URL (with scheme fallback)
            if raw.lowercased().hasPrefix("http://") || raw.lowercased().hasPrefix("https://") {
                urlToLoad = URL(string: raw)
            } else {
                urlToLoad = URL(string: "https://\(raw)")
            }
        }

        if let url = urlToLoad {
            tabs[idx].webView.load(URLRequest(url: url))
        }
    }
}

// MARK: - Tab Model

struct BrowserTab: Identifiable, Equatable {
    let id: UUID
    let webView: WKWebView

    var title: String
    var faviconURL: URL?
    var addressText: String

    var isLoading: Bool
    var canGoBack: Bool
    var canGoForward: Bool

    static func == (lhs: BrowserTab, rhs: BrowserTab) -> Bool { lhs.id == rhs.id }

    /// Creates a fully isolated tab using an ephemeral website data store.
    static func makeIsolated(initialURL: String) -> BrowserTab {
        let config = WKWebViewConfiguration()

        // KEY: per-tab isolation (separate cookie/storage jar)
        config.websiteDataStore = WKWebsiteDataStore.nonPersistent()

        config.allowsAirPlayForMediaPlayback = true
        config.defaultWebpagePreferences.allowsContentJavaScript = true

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.setValue(false, forKey: "drawsBackground")

        let id = UUID()
        let url = URL(string: initialURL) ?? URL(string: "about:blank")!
        webView.load(URLRequest(url: url))

        return BrowserTab(
            id: id,
            webView: webView,
            title: "New Tab",
            faviconURL: faviconFromURL(url),
            addressText: url.absoluteString,
            isLoading: false,
            canGoBack: false,
            canGoForward: false
        )
    }

    static func faviconFromURL(_ url: URL) -> URL? {
        guard let host = url.host else { return nil }
        return URL(string: "https://\(host)/favicon.ico")
    }
}

// MARK: - Tabs Bar (custom)

struct TabsBar: View {
    let tabs: [BrowserTab]
    let selectedID: UUID?
    let onSelect: (UUID) -> Void
    let onNewTab: () -> Void
    let onClose: (UUID) -> Void

    var body: some View {
        HStack(spacing: 10) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(tabs) { tab in
                        TabChip(
                            title: tab.title.isEmpty ? "Untitled" : tab.title,
                            faviconURL: tab.faviconURL,
                            isSelected: tab.id == selectedID,
                            onTap: { onSelect(tab.id) },
                            onClose: { onClose(tab.id) }
                        )
                    }
                }
                .padding(.vertical, 4)
            }

            Button(action: onNewTab) {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 30, height: 28)
            }
            .buttonStyle(.plain)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
            )
        }
        .padding(10)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
        )
    }
}

struct TabChip: View {
    let title: String
    let faviconURL: URL?
    let isSelected: Bool
    let onTap: () -> Void
    let onClose: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                FaviconView(url: faviconURL)

                Text(title)
                    .lineLimit(1)
                    .font(.system(size: 13, weight: .semibold))
                    .opacity(isSelected ? 0.95 : 0.75)

                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .opacity(0.65)
                        .padding(6)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.white.opacity(0.16) : Color.white.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(isSelected ? Color.white.opacity(0.22) : Color.white.opacity(0.10), lineWidth: 1)
        )
    }
}

struct FaviconView: View {
    let url: URL?

    var body: some View {
        Group {
            if let url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable().scaledToFit()
                    default:
                        Image(systemName: "globe")
                            .resizable()
                            .scaledToFit()
                            .opacity(0.6)
                    }
                }
            } else {
                Image(systemName: "globe")
                    .resizable()
                    .scaledToFit()
                    .opacity(0.6)
            }
        }
        .frame(width: 14, height: 14)
        .clipShape(RoundedRectangle(cornerRadius: 3))
    }
}

// MARK: - Toolbar

struct BrowserToolbar: View {
    @Binding var addressText: String
    let canGoBack: Bool
    let canGoForward: Bool
    let onBack: () -> Void
    let onForward: () -> Void
    let onReload: () -> Void
    let onStop: () -> Void
    let isLoading: Bool
    let onSubmitAddress: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            toolbarButton("chevron.left", enabled: canGoBack, action: onBack)
            toolbarButton("chevron.right", enabled: canGoForward, action: onForward)

            Button(action: isLoading ? onStop : onReload) {
                Image(systemName: isLoading ? "xmark" : "arrow.clockwise")
                    .font(.system(size: 13, weight: .semibold))
                    .frame(width: 34, height: 30)
            }
            .buttonStyle(.plain)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.08)))
            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.white.opacity(0.12), lineWidth: 1))

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .opacity(0.55)

                TextField("Search or enter website name", text: $addressText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13, weight: .medium))
                    .onSubmit(onSubmitAddress)
            }
            .padding(.horizontal, 12)
            .frame(height: 34)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(NSColor.textBackgroundColor).opacity(0.55))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
            )
        }
        .padding(10)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
        )
    }

    private func toolbarButton(_ systemName: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 13, weight: .semibold))
                .frame(width: 34, height: 30)
                .opacity(enabled ? 0.95 : 0.35)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.08)))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.white.opacity(0.12), lineWidth: 1))
    }
}

// MARK: - WebView (NSViewRepresentable)

struct WebViewContainer: NSViewRepresentable {
    let tab: BrowserTab
    @EnvironmentObject private var store: BrowserStore

    func makeNSView(context: Context) -> WKWebView {
        tab.webView.navigationDelegate = context.coordinator
        context.coordinator.attachObservers(for: tab)
        return tab.webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        // Keep delegate attached
        if nsView.navigationDelegate == nil {
            nsView.navigationDelegate = context.coordinator
        }
        context.coordinator.ensureObservers(for: tab)
    }

    func makeCoordinator() -> Coordinator { Coordinator(store: store) }

    final class Coordinator: NSObject, WKNavigationDelegate {
        private weak var store: BrowserStore?
        private var observedTabID: UUID?
        private var titleObs: NSKeyValueObservation?
        private var urlObs: NSKeyValueObservation?
        private var loadingObs: NSKeyValueObservation?
        private var backObs: NSKeyValueObservation?
        private var forwardObs: NSKeyValueObservation?

        init(store: BrowserStore) { self.store = store }

        func ensureObservers(for tab: BrowserTab) {
            guard observedTabID != tab.id else { return }
            attachObservers(for: tab)
        }

        func attachObservers(for tab: BrowserTab) {
            observedTabID = tab.id

            titleObs = tab.webView.observe(\.title, options: [.initial, .new]) { [weak self] webView, _ in
                self?.update(tabID: tab.id) { $0.title = webView.title ?? "Untitled" }
            }

            urlObs = tab.webView.observe(\.url, options: [.initial, .new]) { [weak self] webView, _ in
                guard let url = webView.url else { return }
                self?.update(tabID: tab.id) {
                    $0.addressText = url.absoluteString
                    $0.faviconURL = BrowserTab.faviconFromURL(url)
                }
            }

            loadingObs = tab.webView.observe(\.isLoading, options: [.initial, .new]) { [weak self] webView, _ in
                self?.update(tabID: tab.id) { $0.isLoading = webView.isLoading }
            }

            backObs = tab.webView.observe(\.canGoBack, options: [.initial, .new]) { [weak self] webView, _ in
                self?.update(tabID: tab.id) { $0.canGoBack = webView.canGoBack }
            }

            forwardObs = tab.webView.observe(\.canGoForward, options: [.initial, .new]) { [weak self] webView, _ in
                self?.update(tabID: tab.id) { $0.canGoForward = webView.canGoForward }
            }
        }

        private func update(tabID: UUID, mutate: @escaping (inout BrowserTab) -> Void) {
            Task { @MainActor [weak self] in
                guard let self, let store = self.store else { return }
                guard let idx = store.tabs.firstIndex(where: { $0.id == tabID }) else { return }

                var copy = store.tabs[idx]
                mutate(&copy)
                store.tabs[idx] = copy
            }
        }
    }
}
