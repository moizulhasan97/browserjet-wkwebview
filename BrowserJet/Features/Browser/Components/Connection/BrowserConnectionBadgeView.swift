//
//  BrowserConnectionBadgeView.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 16/02/2026.
//


import SwiftUI

struct BrowserConnectionBadgeView: View {
    @Environment(\.appTheme) private var theme

    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(theme.textPrimary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(theme.surfaceControl)
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(theme.strokeControl, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .accessibilityLabel("Connection: \(title)")
    }
}

#Preview {
    VStack(spacing: 12) {
        BrowserConnectionBadgeView(title: "Local")
        BrowserConnectionBadgeView(title: "On VPN")
        BrowserConnectionBadgeView(title: "Premium")
        BrowserConnectionBadgeView(title: "Custom")
    }
    .padding()
    .environment(\.appTheme, BrowserJetLightTheme())
}