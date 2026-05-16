//
//  InfoAlertView.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 02/03/2026.
//

import SwiftUI

// MARK: - White Card
struct InfoAlertChrome<Content: View>: View {
    @Environment(\.appTheme)
    private var theme

    private let minWidth: CGFloat
    private let maxWidth: CGFloat
    private let content: Content

    init(
        minWidth: CGFloat = 320,
        maxWidth: CGFloat = 440,
        @ViewBuilder content: () -> Content
    ) {
        self.minWidth = minWidth
        self.maxWidth = maxWidth
        self.content = content()
    }

    var body: some View {
        content
            .padding(DesignMetrics.screenPadding)
            .frame(minWidth: minWidth, maxWidth: maxWidth)
            .background(theme.surfaceCard)
            .clipShape(RoundedRectangle(cornerRadius: DesignMetrics.cardCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DesignMetrics.cardCornerRadius, style: .continuous)
                    .stroke(theme.strokeCard, lineWidth: DesignMetrics.cardStrokeWidth)
            )
            .shadow(color: .black.opacity(0.12), radius: DesignMetrics.cardShadowRadius, y: DesignMetrics.cardShadowY)
    }
}

// MARK: - Progress-only
struct InfoAlertProgressView: View {
    private let message: String

    init(message: String = ActivationMessages.verifyingStoredKeyProgress) {
        self.message = message
    }

    var body: some View {
        InfoAlertChrome {
            VStack(spacing: DesignMetrics.rowSpacing) {
                BrowserJetLogoMark(iconSize: 48, style: .center)

                ProgressView(message)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

// MARK: - Title + message + OK
struct InfoAlertView: View {
    @Environment(\.designSystem)
    private var designSystem
    @Environment(\.appTheme)
    private var theme

    let title: String
    let message: String
    let buttonTitle: String
    let onDismiss: () -> Void

    init(
        title: String,
        message: String,
        buttonTitle: String = "OK",
        onDismiss: @escaping () -> Void
    ) {
        self.title = title
        self.message = message
        self.buttonTitle = buttonTitle
        self.onDismiss = onDismiss
    }

    var body: some View {
        InfoAlertChrome {
            VStack(spacing: DesignMetrics.sectionSpacing) {
                BrowserJetLogoMark(iconSize: 48, style: .center)

                VStack(alignment: .center, spacing: DesignMetrics.rowSpacing) {
                    Text(title)
                        .font(designSystem.typography.title1.font)
                        .foregroundStyle(theme.textPrimary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)

                    Text(message)
                        .font(designSystem.typography.textBody1.font)
                        .foregroundStyle(theme.textFieldSecondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }

                BrowserJetAppButton(
                    title: buttonTitle,
                    type: .primaryLarge,
                    isDisabled: false,
                    action: onDismiss
                )
            }
        }
    }
}

#Preview("Progress only") {
    InfoAlertProgressView()
        .environment(\.appTheme, BrowserJetDarkTheme())
        .environment(\.designSystem, DesignSystem())
        .padding(40)
        .background(Color.gray.opacity(0.2))
}

#Preview("Error") {
    InfoAlertView(
        title: "Error",
        message: "Something went wrong. Please try again.",
        buttonTitle: "OK"
    ) {}
        .environment(\.appTheme, BrowserJetDarkTheme())
        .environment(\.designSystem, DesignSystem())
}

#Preview("Success") {
    InfoAlertView(
        title: "Success",
        message: "Your license has been shifted to this device.",
        buttonTitle: "OK"
    ) {}
        .environment(\.appTheme, BrowserJetDarkTheme())
        .environment(\.designSystem, DesignSystem())
}
