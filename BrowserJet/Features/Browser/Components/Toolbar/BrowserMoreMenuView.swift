//
//  BrowserMoreMenuView.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 20/02/2026.
//

import SwiftUI

struct BrowserMoreMenuView: View {
    let items: [BrowserMoreMenuItem]
    var isDisabled: Bool = false
    let onSelect: (BrowserMoreMenuItem) -> Void

    var body: some View {
        Menu {
            ForEach(items, id: \.self) { item in
                Button(item.title) {
                    onSelect(item)
                }
                .disabled(!item.isEnabled || isDisabled)
            }
        } label: {
            BrowserToolbarIconButtonStyle(
                systemImageName: "square.grid.2x2",
                tooltip: "More"
            )
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.5 : 1)
        .accessibilityLabel("More")
    }
}

#Preview("More Menu") {
    BrowserMoreMenuView(items: BrowserMenuBuilder.default.moreMenuItems) { item in
        AppLogger.debug("Selected: \(item.title)")
    }
    .padding()
    .background(Color.gray.opacity(0.2))
    .environment(\.appTheme, BrowserJetLightTheme())
}
