//
//  BrowserJetLogoMark.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 16/05/2026.
//

import SwiftUI

struct BrowserJetLogoMark: View {
    enum AlignmentStyle {
        case leading   // launcher header
        case center    // alerts, sheets
    }

    @Environment(\.appTheme)
    private var theme

    var iconSize: CGFloat = 44
    var style: AlignmentStyle = .leading

    private let titleTracking: CGFloat = 1.2
    private let subtitleTracking: CGFloat = 0.8

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(.icLogo) // asset: ic_logo
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: iconSize, height: iconSize)
                // .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text("BROWSERJET")
                    .font(.system(size: 16, weight: .bold, design: .default))
                    .tracking(titleTracking)
                    .foregroundStyle(theme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Text("PROXY BROWSER")
                    .font(.system(size: 11, weight: .regular, design: .default))
                    .tracking(subtitleTracking)
                    .foregroundStyle(theme.textFieldSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
        }
        .frame(
            maxWidth: style == .center ? .infinity : nil,
            alignment: style == .center ? .center : .leading
        )
        // .accessibilityElement(children: .combine)
        // .accessibilityLabel("BrowserJet, Proxy Browser")
    }
}

#Preview("Logo mark – light") {
    BrowserJetLogoMark(style: .center)
        .padding()
        .background(AppBackgroundStyle.browserJetGradient.makeView())
        .environment(\.appTheme, BrowserJetLightTheme())
}

#Preview("Logo mark – dark") {
    BrowserJetLogoMark(style: .center)
        .padding()
        .background(AppBackgroundStyle.browserJetDarkGradient.makeView())
        .environment(\.appTheme, BrowserJetDarkTheme())
}
