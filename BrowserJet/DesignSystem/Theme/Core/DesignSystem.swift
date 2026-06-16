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
    let textFieldStyle: any TextFieldStyleProvider

    init(
        typography: any AppTypography = TextTypography(),
        viewConfig: any ViewConfig = BrowserJetViewConfig(),
        buttonStyle: any ButtonStyleProvider = ThemeButtonStyleProvider(),
        textFieldStyle: any TextFieldStyleProvider = ThemeTextFieldStyleProvider()
    ) {
        self.typography = typography
        self.viewConfig = viewConfig
        self.buttonStyle = buttonStyle
        self.textFieldStyle = textFieldStyle
    }
}
