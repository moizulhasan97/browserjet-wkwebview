//
//  BrowserToolbarIconButtonStyle.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 20/02/2026.
//

import SwiftUI

struct BrowserToolbarIconButtonStyle: View {
    @Environment(\.appTheme)
    private var theme

    let systemImageName: String
    let tooltip: String

    @State private var isHovering = false

    var body: some View {
        Image(systemName: systemImageName)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(theme.textPrimary)
            .frame(width: 28, height: 28)
            .background(theme.surfaceControl.opacity(isHovering ? 0.95 : 0.7))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(theme.strokeControl.opacity(isHovering ? 1.0 : 0.8), lineWidth: 1)
            )
            .help(tooltip)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.12)) {
                    isHovering = hovering
                }
            }
    }
}
