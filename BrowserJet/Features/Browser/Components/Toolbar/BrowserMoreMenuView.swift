//
//  BrowserMoreMenuView.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 20/02/2026.
//
import SwiftUI

struct BrowserMoreMenuView: View {
    let entries: [MoreMenuEntry]
    var isDisabled: Bool = false
    let onSelect: (BrowserMoreMenuItem) -> Void
    
    var body: some View {
        Menu {
            ForEach(entries, id: \.item) { entry in
                Button(entry.title) {
                    onSelect(entry.item)
                }
                .disabled(isDisabled)
                .help(entry.tooltip)
                .accessibilityLabel(entry.title)
                .accessibilityHint(entry.tooltip)
            }
        } label: {
            BrowserToolbarIconButtonStyle(
                systemImageName: "square.grid.2x2",
                tooltip: "More"
            )
        }
        .buttonStyle(.plain)
        .disabled(isDisabled || entries.isEmpty)
        .opacity(isDisabled ? 0.5 : 1)
        .accessibilityLabel("More")
    }
}

#Preview("More Menu") {
    BrowserMoreMenuView(entries: BrowserMenuBuilder.default.moreMenuEntries) { item in
        AppLogger.debug("Selected: \(item)")
    }
    .padding()
    .background(Color.gray.opacity(0.2))
    .environment(\.appTheme, BrowserJetLightTheme())
}
