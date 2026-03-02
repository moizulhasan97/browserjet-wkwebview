//
//  InfoAlertView.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 02/03/2026.
//

import SwiftUI

struct InfoAlertView: View {
    @Environment(\.designSystem) private var designSystem
    @Environment(\.appTheme) private var theme

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
        VStack(spacing: DesignMetrics.sectionSpacing) {
            Image(.icLogoDescription)

            VStack(alignment: .leading, spacing: DesignMetrics.rowSpacing) {
                Text(title)
                    .font(designSystem.typography.title1.font)
                    .foregroundStyle(theme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(designSystem.typography.textBody1.font)
                    .foregroundStyle(theme.textFieldSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, alignment: .center)
            }

            BrowserJetAppButton(
                title: buttonTitle,
                type: .primaryLarge,
                height: 48,
                isDisabled: false,
                action: onDismiss
            )
        }
        .padding(DesignMetrics.screenPadding)
        .frame(minWidth: 320, maxWidth: 440)
        .background(theme.surfaceCard)
        .clipShape(RoundedRectangle(cornerRadius: DesignMetrics.cardCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DesignMetrics.cardCornerRadius, style: .continuous)
                .stroke(theme.strokeCard, lineWidth: DesignMetrics.cardStrokeWidth)
        )
    }
}

#Preview("Error") {
    InfoAlertView(
        title: "Error",
        message: "Something went wrong. Please try again.",
        buttonTitle: "OK",
        onDismiss: {}
    )
    .environment(\.appTheme, BrowserJetDarkTheme())
    .environment(\.designSystem, DesignSystem())
}

#Preview("Success") {
    InfoAlertView(
        title: "Success",
        message: "Your license has been shifted to this device.",
        buttonTitle: "OK",
        onDismiss: {}
    )
    .environment(\.appTheme, BrowserJetDarkTheme())
    .environment(\.designSystem, DesignSystem())
}
