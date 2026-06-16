//
//  ThemeWindowAppearance.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 17/05/2026.
//

import AppKit

@MainActor
enum ThemeWindowAppearance {
    /// Applies light / dark / system appearance to every open app window.
    static func apply(mode: ThemeManager.Mode) {
        guard let app = NSApp else { return }

        let appearance: NSAppearance? = switch mode {
        case .light: NSAppearance(named: .aqua)
        case .dark: NSAppearance(named: .darkAqua)
        case .system: nil
        }

        for window in app.windows {
            window.appearance = appearance
        }
    }
}
