//
//  ButtonStyleProvider.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 12/02/2026.
//

import SwiftUI

protocol ButtonStyleProvider {
    func style(
        for type: BrowserJetButtonStyle.ButtonType,
        typography: any AppTypography,
        viewConfig: any ViewConfig,
        theme: any AppTheme
    ) -> any BrowserJetButtonStyleProtocol
}

struct ThemeButtonStyleProvider: ButtonStyleProvider {
    func style(
        for type: BrowserJetButtonStyle.ButtonType,
        typography: any AppTypography,
        viewConfig: any ViewConfig,
        theme: any AppTheme
    ) -> any BrowserJetButtonStyleProtocol {
        switch type {
        case .primaryLarge:
            BrowserJetPrimaryLargeButtonStyle(
                cornerRadius: .capsule,
                borderColor: .clear,
                borderDisabledColor: .clear,
                borderHighlightedColor: .clear,
                borderWidth: 0,
                font: typography.button.font,
                backgroundColor: ._0088_FF,
                backgroundDisabledColor: ._0088_FF.opacity(0.85),
                backgroundHighlightedColor: ._0088_FF.opacity(0.85),
                titleColor: .white,
                titleDisabledColor: .white.opacity(0.85),
                titleHighlightedColor: .white.opacity(0.85)
            )

        case .secondaryLarge:
            BrowserJetSecondaryLargeButtonStyle(
                cornerRadius: .capsule,
                borderColor: theme.strokeControl,
                borderDisabledColor: theme.strokeControl.opacity(0.4),
                borderHighlightedColor: theme.strokeControl,
                borderWidth: 1,
                font: typography.button.font,
                backgroundColor: theme.surfaceControl,
                backgroundDisabledColor: theme.surfaceControl.opacity(0.6),
                backgroundHighlightedColor: theme.surfaceControl.opacity(0.85),
                titleColor: theme.textPrimary,
                titleDisabledColor: theme.textPrimary.opacity(0.5),
                titleHighlightedColor: theme.textPrimary
            )
        }
    }
}

struct BrowserJetPrimaryLargeButtonStyle: BrowserJetButtonStyleProtocol {
    let cornerRadius: CornerRadius
    let borderColor: Color
    let borderDisabledColor: Color
    let borderHighlightedColor: Color
    let borderWidth: CGFloat

    let font: Font

    let backgroundColor: Color
    let backgroundDisabledColor: Color
    let backgroundHighlightedColor: Color

    let titleColor: Color
    let titleDisabledColor: Color
    let titleHighlightedColor: Color
}

struct BrowserJetSecondaryLargeButtonStyle: BrowserJetButtonStyleProtocol {
    let cornerRadius: CornerRadius
    let borderColor: Color
    let borderDisabledColor: Color
    let borderHighlightedColor: Color
    let borderWidth: CGFloat

    let font: Font

    let backgroundColor: Color
    let backgroundDisabledColor: Color
    let backgroundHighlightedColor: Color

    let titleColor: Color
    let titleDisabledColor: Color
    let titleHighlightedColor: Color
}

// MARK: - Previews

private struct ButtonTypePreviewRow: View {
    let title: String
    let type: BrowserJetButtonStyle.ButtonType
    let isDisabled: Bool

    var body: some View {
        BrowserJetAppButton(
            title: title,
            type: type,
            height: 48,
            isDisabled: isDisabled,
            action: {}
        )
    }
}

private func buttonStylePreviewContent(theme: any AppTheme) -> some View {
    let design = DesignSystem()
    return ScrollView {
        VStack(alignment: .leading, spacing: 20) {
            previewSectionHeader("Primary large")
            ButtonTypePreviewRow(title: "Enabled", type: .primaryLarge, isDisabled: false)
            ButtonTypePreviewRow(title: "Disabled", type: .primaryLarge, isDisabled: true)

            previewSectionHeader("Secondary large")
            ButtonTypePreviewRow(title: "Enabled", type: .secondaryLarge, isDisabled: false)
            ButtonTypePreviewRow(title: "Disabled", type: .secondaryLarge, isDisabled: true)
        }
        .padding(24)
        .frame(maxWidth: 400)
    }
    .environment(\.designSystem, design)
    .environment(\.appTheme, theme)
}

private func previewSectionHeader(_ text: String) -> some View {
    Text(text)
        .font(.headline)
        .foregroundStyle(.secondary)
}

#Preview("Button types — light") {
    buttonStylePreviewContent(theme: BrowserJetLightTheme())
        .background(BrowserJetLightTheme().surfaceCard)
}

#Preview("Button types — dark") {
    buttonStylePreviewContent(theme: BrowserJetDarkTheme())
        .background(BrowserJetDarkTheme().surfaceCard)
}
