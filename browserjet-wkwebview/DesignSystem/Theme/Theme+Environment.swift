//
//  Theme+Environment.swift
//  browserjet-wkwebview
//
//  Created by Moiz Ul Hasan on 22/01/2026.
//

import SwiftUI

private struct ThemeKey: EnvironmentKey {
    static let defaultValue: any AppTheme = BrowserJetLightTheme()
}

extension EnvironmentValues {
    var appTheme: any AppTheme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}
