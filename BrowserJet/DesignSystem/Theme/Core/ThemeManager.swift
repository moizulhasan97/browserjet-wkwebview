//
//  ThemeManager.swift
//  browserjet-wkwebview
//
//  Created by Moiz Ul Hasan on 22/01/2026.
//

import SwiftUI
import Combine

@MainActor
final class ThemeManager: ObservableObject {
    enum Mode: Equatable {
        case system
        case light
        case dark
    }

    @Published var mode: Mode = .system

    private let lightTheme: any AppTheme
    private let darkTheme: any AppTheme

    init(
        lightTheme: any AppTheme = BrowserJetLightTheme(),
        darkTheme: any AppTheme = BrowserJetDarkTheme()
    ) {
        self.lightTheme = lightTheme
        self.darkTheme = darkTheme
    }

    func theme(for colorScheme: ColorScheme) -> any AppTheme {
        switch mode {
        case .system:
            return colorScheme == .dark ? darkTheme : lightTheme
        case .light:
            return lightTheme
        case .dark:
            return darkTheme
        }
    }
}
