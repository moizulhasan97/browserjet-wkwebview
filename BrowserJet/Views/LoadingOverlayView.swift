//
//  LoadingOverlayView.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 24/02/2026.
//

import SwiftUI

struct LoadingOverlayView: View {
    @Environment(\.appTheme)
    private var theme
    @Environment(\.designSystem)
    private var designSystem

    // optional label underneath the spinner
    var message: String?

    var body: some View {
        ZStack {
            VStack(spacing: 12) {
                ProgressView()
                    .controlSize(.regular)
                    .tint(theme.accent)

                if let message {
                    Text(message)
                        .font(designSystem.typography.textBody1.font)
                        .foregroundStyle(theme.textPrimary)
                }
            }
            .padding(24)
            .background(theme.accent.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: DesignMetrics.controlCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DesignMetrics.controlCornerRadius, style: .continuous)
                    .stroke(theme.accent.opacity(0.25), lineWidth: 1)
            )
            .shadow(color: theme.accent.opacity(0.15), radius: 20, x: 0, y: 6)
        }
    }
}

// MARK: - Previews
#Preview("Spinner – Variants") {
    HStack(spacing: 32) {
        // Spinner only
        VStack(spacing: 12) {
            Text("No message")
                .font(.caption)
                .foregroundStyle(.secondary)
            LoadingOverlayView()
        }

        // Spinner + message
        VStack(spacing: 12) {
            Text("With message")
                .font(.caption)
                .foregroundStyle(.secondary)
            LoadingOverlayView(message: "Verifying...")
        }
    }
    .padding(40)
    .background(AppBackgroundStyle.browserJetGradient.makeView())
    .environment(\.appTheme, BrowserJetLightTheme())
    .environment(\.designSystem, DesignSystem())
}

#Preview("Overlay – On Content") {
    LoadingOverlayPreviewHost()
        .environment(\.appTheme, BrowserJetLightTheme())
        .environment(\.designSystem, DesignSystem())
}

private struct LoadingOverlayPreviewHost: View {
    @State private var isLoading = true

    var body: some View {
        ZStack {
            // Simulated screen content
            VStack(spacing: 20) {
                CardContainer {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("License Key")
                            .font(.system(size: 13, weight: .medium))
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.gray.opacity(0.12))
                            .frame(height: 44)
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(Color.blue.opacity(0.85))
                            .frame(height: 48)
                            .overlay(Text("Verify").foregroundStyle(.white).font(.system(size: 15, weight: .semibold)))
                    }
                }

                // Toggle sits outside the overlay so it stays tappable
                Button(isLoading ? "Hide Spinner" : "Show Spinner") {
                    withAnimation { isLoading.toggle() }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .frame(width: 360)
            .background(AppBackgroundStyle.browserJetGradient.makeView())

            // Overlay
            if isLoading {
                LoadingOverlayView(message: "Verifying...")
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isLoading)
        .frame(width: 360, height: 340)
    }
}
