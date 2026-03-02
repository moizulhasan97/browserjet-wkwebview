//
//  ShiftLicenseView.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 02/03/2026.
//

import SwiftUI

struct ShiftLicenseView: View {
    
    @Environment(\.designSystem) private var designSystem
    @Environment(\.appTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: ShiftViewModel
    private let key: String
    private let email: String
    var onShiftSucceeded: (() -> Void)?
    
    init(
        key: String,
        email: String,
        onShiftSucceeded: (() -> Void)? = nil
    ) {
        self.key = key
        self.email = email
        self.onShiftSucceeded = onShiftSucceeded
        _viewModel = StateObject(wrappedValue: ShiftViewModel(key: key, email: email, onShiftSucceeded: onShiftSucceeded))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignMetrics.sectionSpacing) {
            header
            deviceRow
        }
        .onAppear { viewModel.onAppear() }
        .loadingOverlay(isLoading: viewModel.isLoading)
        .padding(DesignMetrics.screenPadding)
        .frame(minWidth: 400, minHeight: 280)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: DesignMetrics.rowSpacing) {
            Text("Shift license")
                .font(designSystem.typography.title1.font)
                .foregroundStyle(theme.textPrimary)

            Text("Your key is registered on another device. Select it below to shift here.")
                .font(designSystem.typography.textBody1.font)
                .foregroundStyle(theme.textFieldSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var deviceRow: some View {
        if let pcName = viewModel.pcName, !pcName.isEmpty {
            ShiftDeviceRow(deviceName: pcName, isDisabled: viewModel.isLoading) {
                viewModel.didTapShift()
            }
        } else if let error = viewModel.errorMessage {
            Text(error)
                .font(designSystem.typography.textBody1.font)
                .foregroundStyle(theme.danger)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, DesignMetrics.rowSpacing)
        } else if viewModel.isLoading {
            HStack(spacing: DesignMetrics.rowSpacing) {
                ProgressView()
                    .scaleEffect(0.8)
                Text("Loading device…")
                    .font(designSystem.typography.textBody1.font)
                    .foregroundStyle(theme.textFieldSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, DesignMetrics.rowSpacing)
        } else {
            Text("No device name available.")
                    .font(designSystem.typography.textBody1.font)
                    .foregroundStyle(theme.textFieldSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, DesignMetrics.rowSpacing)
        }
    }
}

// MARK: - Device row
private struct ShiftDeviceRow: View {
    @Environment(\.designSystem) private var designSystem
    @Environment(\.appTheme) private var theme

    let deviceName: String
    let isDisabled: Bool
    let onShift: () -> Void
    
    var body: some View {
        CardContainer(padding: DesignMetrics.cardPadding) {
            HStack(spacing: DesignMetrics.cardPadding) {
                Image(systemName: "desktopcomputer")
                    .font(.title2)
                    .foregroundStyle(theme.textFieldSecondary)

                Text(deviceName)
                    .font(designSystem.typography.textBody1.font)
                    .foregroundStyle(theme.textPrimary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                BrowserJetAppButton(
                    title: "Shift",
                    type: .primaryLarge,
                    height: 44,
                    isDisabled: isDisabled,
                    action: onShift
                )
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onTapGesture {
            onShift()
        }
    }
}

#Preview("ShiftLicenseView") {
    ShiftLicenseView(key: "preview-key", email: "preview@example.com") //, getPCDetails: {_ in "desktop-preview-key"})
        .environment(\.appTheme, BrowserJetDarkTheme())
        .environment(\.designSystem, DesignSystem())
        .frame(width: 440, height: 320)
}
