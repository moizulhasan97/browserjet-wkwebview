//
//  BrowserMoreMenuView.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 20/02/2026.
//

import SwiftUI

struct BrowserMoreMenuView: View {
    let items: [BrowserMoreMenuItem]
    let onSelect: (BrowserMoreMenuItem) -> Void

    var body: some View {
        Menu {
            ForEach(items, id: \.self) { item in
                Button(item.title) {
                    onSelect(item)
                }
                .disabled(!item.isEnabled)
            }
        } label: {
            BrowserToolbarIconButtonStyle(
                systemImageName: "square.grid.2x2",
                tooltip: "More"
            )
        }
        //.menuStyle(.borderlessButton) // important for macOS look
        .buttonStyle(.plain)          // makes it match your toolbar buttons
        .accessibilityLabel("More")
    }
}

#Preview("More Menu") {
    BrowserMoreMenuView(items: BrowserMenuBuilder.default.moreMenuItems) { item in
        print("Selected:", item.title)
    }
    .padding()
    .background(Color.gray.opacity(0.2))
    .environment(\.appTheme, BrowserJetLightTheme())
}
