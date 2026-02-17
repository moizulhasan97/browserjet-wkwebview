//
//  BrowserConnectionBadgeView.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 16/02/2026.
//


import SwiftUI

struct BrowserConnectionBadgeView: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.designSystem) private var designSystem
    
    let proxyType: ProxyType
    
    var body: some View {
        Text(proxyType.statusTitle)
            .font(designSystem.typography.heading1.font)
            .foregroundStyle(textColor)
            .frame(height: 34.0)
            .padding(.horizontal, 10)
            .background(theme.surfaceControl)
            .overlay(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .stroke(theme.strokeControl, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
    
    private var textColor: Color {
        proxyType.isLocal ? theme.textPrimary : theme.vpnConnection
    }
}

#Preview {
    VStack(spacing: 12) {
        BrowserConnectionBadgeView(proxyType: .local)
        BrowserConnectionBadgeView(proxyType: .proxy(.custom))
    }
    .padding()
    .environment(\.appTheme, BrowserJetLightTheme())
    .environment(\.designSystem, DesignSystem())
}
