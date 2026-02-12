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
        viewConfig: any ViewConfig
    ) -> any BrowserJetButtonStyleProtocol
}

struct ThemeButtonStyleProvider: ButtonStyleProvider {
    func style(
        for type: BrowserJetButtonStyle.ButtonType,
        typography: any AppTypography,
        viewConfig: any ViewConfig
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
