//
//  BrowserTabStripTitlebarAccessoryController.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 28/05/2026.
//

import AppKit
import SwiftUI

/// Root hosted in the browser window titlebar so tab clicks/drags are not swallowed
/// by the AppKit titlebar drag region under `.fullSizeContentView`.
private struct BrowserTabStripTitlebarRoot: View {
    @ObservedObject var state: BrowserWindowState
    @ObservedObject var themeManager: ThemeManager
    let sessionManager: SessionManager
    let resolvedColorScheme: ColorScheme

    private var accessoryVerticalInset: CGFloat {
        (BrowserTabsStripMetrics.accessoryHeight - BrowserTabsStripMetrics.visualHeight) / 2
    }

    var body: some View {
        BrowserTabsStripView(state: state)
            .frame(maxWidth: .infinity)
            .frame(height: BrowserTabsStripMetrics.visualHeight)
            .padding(.vertical, accessoryVerticalInset)
            .frame(height: BrowserTabsStripMetrics.accessoryHeight)
            .environmentObject(sessionManager)
            .environment(\.appTheme, themeManager.theme(for: resolvedColorScheme))
            .environment(\.designSystem, DesignSystem())
            .id(themeManager.appearanceIdentity)
    }
}

@MainActor
final class BrowserTabStripTitlebarAccessoryController: NSTitlebarAccessoryViewController {
    private let hostingController: NSHostingController<BrowserTabStripTitlebarRoot>

    init(
        state: BrowserWindowState,
        themeManager: ThemeManager,
        sessionManager: SessionManager,
        resolvedColorScheme: ColorScheme
    ) {
        let root = BrowserTabStripTitlebarRoot(
            state: state,
            themeManager: themeManager,
            sessionManager: sessionManager,
            resolvedColorScheme: resolvedColorScheme
        )
        hostingController = NSHostingController(rootView: root)

        super.init(nibName: nil, bundle: nil)

        layoutAttribute = .bottom
        fullScreenMinHeight = BrowserTabsStripMetrics.accessoryHeight

        let container = NSView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.wantsLayer = true
        container.layer?.backgroundColor = NSColor.clear.cgColor

        let hostedView = hostingController.view
        hostedView.translatesAutoresizingMaskIntoConstraints = false
        hostedView.wantsLayer = true
        hostedView.layer?.backgroundColor = NSColor.clear.cgColor
        container.addSubview(hostedView)

        NSLayoutConstraint.activate([
            hostedView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            hostedView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            hostedView.topAnchor.constraint(equalTo: container.topAnchor),
            hostedView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            container.heightAnchor.constraint(equalToConstant: BrowserTabsStripMetrics.accessoryHeight)
        ])

        view = container
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
