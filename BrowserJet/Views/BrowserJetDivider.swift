//
//  BrowserJetDivider.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 11/02/2026.
//


import SwiftUI

struct BrowserJetDivider: View {
    @Environment(\.designSystem)
    private var designSystem
    @Environment(\.appTheme)
    private var theme

    private let thickness: CGFloat
    private let opacity: Double
    private let horizontalPadding: CGFloat
    private let verticalPadding: CGFloat

    init(
        thickness: CGFloat = 1,
        opacity: Double = 0.15,
        horizontalPadding: CGFloat = 0,
        verticalPadding: CGFloat = 0
    ) {
        self.thickness = thickness
        self.opacity = opacity
        self.horizontalPadding = horizontalPadding
        self.verticalPadding = verticalPadding
    }

    var body: some View {
        Rectangle()
            .fill(theme.divider)
            .frame(height: thickness)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
    }
}

#Preview {
    BrowserJetDivider(
        thickness: 1,
        opacity: 0.15,
        horizontalPadding: 0,
        verticalPadding: 8
    )
}
