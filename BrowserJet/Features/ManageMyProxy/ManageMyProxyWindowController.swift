//
//  ManageMyProxyWindowController.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 07/07/2026.
//


import SwiftUI

@MainActor
final class ManageMyProxyWindowController {
    static let shared = ManageMyProxyWindowController()

    private var windowController: BrowserJetWindowController<ManageMyProxyHostingRoot>?

    private init() {}

    func show(
        themeManager: ThemeManager,
        colorScheme: ColorScheme,
        onActivated: @escaping (ProxyGroup, ProxyRotationType) -> Void
    ) {
        guard ManageMyProxyAvailability.isFeatureEnabled else {
            AppLogger.warning("ManageMyProxy: show() called while feature flag is disabled — ignoring")
            return
        }

        let theme = themeManager.theme(for: colorScheme)

        let viewModel = ManageMyProxyViewModel(
            onCustomProxyActivated: { [weak self] group, rotation in
                onActivated(group, rotation)
                self?.close()
            }
        )

        let root = ManageMyProxyHostingRoot(viewModel: viewModel, theme: theme)

        let controller = BrowserJetWindowController(
            titledWindowTitle: ManageMyProxyMessages.windowTitle,
            content: root,
            size: NSSize(width: 640, height: 680),
            resizable: false,
            cornerRadius: 18
        )

        windowController = controller
        controller.show()
    }

    func close() {
        windowController?.close()
        windowController = nil
    }
}

private struct ManageMyProxyHostingRoot: View {
    @ObservedObject var viewModel: ManageMyProxyViewModel
    let theme: any AppTheme

    var body: some View {
        ManageMyProxyRootView(viewModel: viewModel)
            .environment(\.appTheme, theme)
            .environment(\.designSystem, DesignSystem())
    }
}
