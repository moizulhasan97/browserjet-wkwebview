//
//  TextFieldStyleProvider.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 23/02/2026.
//

import SwiftUI

protocol TextFieldStyleProvider {
    func style(
        for type: BrowserJetTextFieldType,
        typography: any AppTypography,
        viewConfig: any ViewConfig,
        theme: any AppTheme
    ) -> any BrowserJetTextFieldStyleProtocol
}

struct ThemeTextFieldStyleProvider: TextFieldStyleProvider {
    func style(
        for type: BrowserJetTextFieldType,
        typography: any AppTypography,
        viewConfig: any ViewConfig,
        theme: any AppTheme
    ) -> any BrowserJetTextFieldStyleProtocol {
        switch type {
        case .launcherAddress:
            return BrowserJetTextFieldStyle(
                height: DesignMetrics.launcherAddressFieldHeight,
                cornerRadius: .fixed(DesignMetrics.controlCornerRadius),
                font: typography.launcherField.font,
                backgroundColor: theme.surfaceControl,
                backgroundDisabledColor: theme.surfaceControl.opacity(0.7),
                backgroundHighlightedColor: theme.surfaceControl,
                textColor: theme.textPrimary,
                textDisabledColor: theme.textPrimary.opacity(0.6),
                textHighlightedColor: theme.textPrimary,
                placeholderColor: theme.textFieldSecondary,
                borderColor: theme.strokeControl,
                borderDisabledColor: theme.strokeControl.opacity(0.6),
                borderHighlightedColor: theme.accent.opacity(0.35),
                borderWidth: DesignMetrics.controlStrokeWidth,
                contentInsets: .init(top: 0, leading: 0, bottom: 0, trailing: 0)
            )

        case .browserAddress:
            return BrowserJetTextFieldStyle(
                height: DesignMetrics.browserAddressFieldHeight,
                cornerRadius: .capsule,
                font: typography.launcherField.font,
                backgroundColor: theme.surfaceControl,
                backgroundDisabledColor: theme.surfaceControl.opacity(0.7),
                backgroundHighlightedColor: theme.surfaceControl,
                textColor: theme.textPrimary,
                textDisabledColor: theme.textPrimary.opacity(0.6),
                textHighlightedColor: theme.textPrimary,
                placeholderColor: theme.textFieldSecondary,
                borderColor: theme.strokeControl.opacity(0.65),
                borderDisabledColor: theme.strokeControl.opacity(0.55),
                borderHighlightedColor: theme.strokeControl.opacity(0.9),
                borderWidth: DesignMetrics.controlStrokeWidth,
                contentInsets: .init(top: 0, leading: 0, bottom: 0, trailing: 0)
            )

        case .activationField:
            return BrowserJetTextFieldStyle(
                height: 34,
                cornerRadius: .fixed(DesignMetrics.controlCornerRadius),
                font: typography.activationField.font,
                backgroundColor: theme.surfaceControl,
                backgroundDisabledColor: theme.surfaceControl.opacity(0.7),
                backgroundHighlightedColor: theme.surfaceControl,
                textColor: theme.textPrimary,
                textDisabledColor: theme.textPrimary.opacity(0.6),
                textHighlightedColor: theme.textPrimary,
                placeholderColor: theme.textFieldSecondary,
                borderColor: theme.strokeControl,
                borderDisabledColor: theme.strokeControl.opacity(0.6),
                borderHighlightedColor: theme.accent.opacity(0.35),
                borderWidth: DesignMetrics.controlStrokeWidth,
                contentInsets: .init(top: 0, leading: 0, bottom: 0, trailing: 0)
            )
        }
    }
}

struct BrowserJetTextFieldStyle: BrowserJetTextFieldStyleProtocol {
    let height: CGFloat
    let cornerRadius: CornerRadius
    let font: Font

    let backgroundColor: Color
    let backgroundDisabledColor: Color
    let backgroundHighlightedColor: Color

    let textColor: Color
    let textDisabledColor: Color
    let textHighlightedColor: Color

    let placeholderColor: Color

    let borderColor: Color
    let borderDisabledColor: Color
    let borderHighlightedColor: Color
    let borderWidth: CGFloat

    let contentInsets: EdgeInsets
}
