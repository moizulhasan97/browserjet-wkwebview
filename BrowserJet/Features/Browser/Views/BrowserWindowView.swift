//
//  BrowserWindowView.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 17/02/2026.
//


import SwiftUI
import WebKit

struct BrowserWindowView: View {
    @ObservedObject var state: BrowserWindowState
    let request: LaunchRequest
    
    var body: some View {
        VStack(spacing: 0) {
            BrowserChromeView(
                state: state,
                menu: .default,
                onToolbarAction: { action in
                    // MVP: no business logic yet
                    AppLogger.info("Toolbar action: \(action)")
                }
            )
            
            // Web content area
            Group {
                if let tab = state.selectedTab {
                    WebViewContainer(
                        tab: tab,
                        onOpenInNewTab: { url in
                            state.addTab(url: url)
                        }
                    )
                    .id(tab.id)
                } else {
                    Text("No tab selected")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .onAppear {
            bootstrapInitialTabsIfNeeded()
            loadInitialAddressIfNeeded()
        }
    }
    
    // MARK: - Bootstrapping
    
    private func bootstrapInitialTabsIfNeeded() {
        // BrowserWindowState creates 1 tab in init(). We add more here based on request.
        let desired = max(1, request.numberOfTabs)
        let missing = desired - state.tabs.count
        guard missing > 0 else { return }
        
        for _ in 0..<missing {
            state.addTab()
        }
    }
    
    private func loadInitialAddressIfNeeded() {
        guard let tab = state.selectedTab else { return }
        let trimmed = request.address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        tab.load(trimmed)
    }
}
