//
//  Untitled.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 11/02/2026.
//

struct DesignSystem {
    let typography: any AppTypography
    let viewConfig: any ViewConfig
    let buttonStyle: any ButtonStyleProvider

    init(
        typography: any AppTypography = TextTypography(),
        viewConfig: any ViewConfig = BrowserJetViewConfig(),
        buttonStyle: any ButtonStyleProvider = ThemeButtonStyleProvider()
    ) {
        self.typography = typography
        self.viewConfig = viewConfig
        self.buttonStyle = buttonStyle
    }
}
