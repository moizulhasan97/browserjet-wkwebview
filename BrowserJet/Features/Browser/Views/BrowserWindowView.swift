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
    }
}
