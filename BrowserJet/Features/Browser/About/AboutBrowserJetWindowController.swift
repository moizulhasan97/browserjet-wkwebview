//
//  AboutBrowserJetWindowController.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 07/05/2026.
//

// import AppKit
import SwiftUI

@MainActor
final class AboutBrowserJetWindowController {
    static let shared = AboutBrowserJetWindowController()

    private var windowController: BrowserJetWindowController<AboutBrowserJetHostingRoot>?

    private init() {}

    func show(themeManager: ThemeManager, colorScheme: ColorScheme) {
        let licenseStore = LicenseStore()
        let keyStore: KeyValueStoring = UserDefaultsKeyValueStore()

        guard let license = licenseStore.load(),
            AboutBrowserJetContentBuilder.canPresent(license: license) else {
            AppLogger.warning("About BrowserJet: unavailable (missing or ineligible license)")
            return
        }

        let rawKey = keyStore.object(forKey: StorageKeys.licenseKey) as? String ?? ""
        LicenseAccountStore.shared.refresh()

        let model = AboutBrowserJetContentBuilder.buildModel(
            license: license,
            licenseKeyFromStore: rawKey
        )

        let theme = themeManager.theme(for: colorScheme)

        let root = AboutBrowserJetHostingRoot(
            model: model,
            theme: theme
        ) { [weak self] in
            self?.windowController?.close()
            self?.windowController = nil
        }

        let aboutWindowController = BrowserJetWindowController(
            titledWindowTitle: "About BrowserJet",
            content: root,
            size: NSSize(width: 520, height: 560),
            titleBarHidden: false,
            resizable: false,
            cornerRadius: 16,
            borderlessChrome: false
        )

        windowController = aboutWindowController
        aboutWindowController.show()
    }
}

private struct AboutBrowserJetHostingRoot: View {
    let model: AboutBrowserJetDisplayModel
    let theme: any AppTheme
    let onClose: () -> Void

    var body: some View {
        AboutBrowserJetView(model: model, onClose: onClose)
            .environment(\.appTheme, theme)
            .environment(\.designSystem, DesignSystem())
    }
}
