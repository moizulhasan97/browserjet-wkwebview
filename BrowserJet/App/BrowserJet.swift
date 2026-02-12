//
//  BrowserJet.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 12/02/2026.
//

import SwiftUI

@main
struct BrowserJet: App {
    
    private let themeManager = ThemeManager()
    private let sessionManager = SessionManager()
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
    
    init() {
        let themeManager = self.themeManager
        let sessionManager = self.sessionManager
        DispatchQueue.main.async {
            WindowManager.shared.showLauncher(
                themeManager: themeManager,
                sessionManager: sessionManager,
                appConfiguration: .development
            )
        }
    }
}
