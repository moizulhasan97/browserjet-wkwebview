//
//  NavigationErrorView.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 24/09/2026.
//

import SwiftUI

/// Native error page shown over a tab's web view when a main-frame navigation
/// fails (Chrome / Safari parity). The `WKWebView` stays mounted underneath, so
/// its history, process and scroll position survive until the next commit.
struct NavigationErrorView: View {
    @Environment(\.designSystem)
    private var designSystem
    @Environment(\.appTheme)
    private var theme
    @Environment(\.colorScheme)
    private var colorScheme

    private let presentation: NavigationErrorPresentation
    private let isRetrying: Bool
    private let onRetry: () -> Void

    init(
        failure: TabNavigationFailure,
        isProxied: Bool,
        isRetrying: Bool,
        onRetry: @escaping () -> Void
    ) {
        self.presentation = NavigationErrorPresentation(failure: failure, isProxied: isProxied)
        self.isRetrying = isRetrying
        self.onRetry = onRetry
    }

    var body: some View {
        ZStack {
            AppBackgroundStyle.brandGradient(for: colorScheme).makeView()

            VStack(alignment: .leading, spacing: DesignMetrics.sectionSpacing) {
                Image(systemName: presentation.symbolName)
                    .font(.system(size: Layout.iconSize, weight: .regular))
                    .foregroundStyle(theme.textFieldSecondary)
                    .accessibilityHidden(true)

                textContent

                BrowserJetAppButton(
                    title: isRetrying
                        ? NavigationErrorMessages.retryingButtonTitle
                        : NavigationErrorMessages.retryButtonTitle,
                    type: .primaryLarge,
                    width: .fixed(width: Layout.retryButtonWidth),
                    isDisabled: isRetrying,
                    action: onRetry
                )
            }
            .frame(maxWidth: Layout.contentMaxWidth, alignment: .leading)
            .padding(DesignMetrics.screenPadding)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .accessibilityElement(children: .contain)
    }

    private var textContent: some View {
        VStack(alignment: .leading, spacing: DesignMetrics.rowSpacing) {
            Text(presentation.title)
                .font(designSystem.typography.title1.font)
                .foregroundStyle(theme.textPrimary)
                .accessibilityAddTraits(.isHeader)

            Text(presentation.message)
                .font(designSystem.typography.textBody1.font)
                .foregroundStyle(theme.textFieldSecondary)

            if let suggestion = presentation.suggestion {
                Text(suggestion)
                    .font(designSystem.typography.textBody1.font)
                    .foregroundStyle(theme.textFieldSecondary)
            }

            Text(presentation.diagnosticCode)
                .font(designSystem.typography.textCaption.font)
                .foregroundStyle(theme.textFieldSecondary.opacity(0.8))
                .textSelection(.enabled)
        }
        .multilineTextAlignment(.leading)
        .fixedSize(horizontal: false, vertical: true)
    }
}

private extension NavigationErrorView {
    enum Layout {
        static let iconSize: CGFloat = 44
        static let contentMaxWidth: CGFloat = 520
        static let retryButtonWidth = 160
    }
}

#if DEBUG
private extension TabNavigationFailure {
    static let previewConnectionLost = TabNavigationFailure(
        kind: .connectionLost,
        failingURL: URL(string: "https://www.example.com/checkout"),
        domain: NSURLErrorDomain,
        code: NSURLErrorNetworkConnectionLost
    )
}

#Preview("Connection lost — proxied, light") {
    NavigationErrorView(
        failure: .previewConnectionLost,
        isProxied: true,
        isRetrying: false
    ) {}
        .frame(width: 900, height: 600)
        .environment(\.appTheme, BrowserJetLightTheme())
        .environment(\.designSystem, DesignSystem())
}

#Preview("Connection lost — retrying, dark") {
    NavigationErrorView(
        failure: .previewConnectionLost,
        isProxied: false,
        isRetrying: true
    ) {}
        .frame(width: 900, height: 600)
        .environment(\.appTheme, BrowserJetDarkTheme())
        .environment(\.designSystem, DesignSystem())
        .preferredColorScheme(.dark)
}
#endif
