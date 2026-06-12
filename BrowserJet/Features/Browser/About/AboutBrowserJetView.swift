//
//  AboutBrowserJetView.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 07/05/2026.
//

import SwiftUI

struct AboutBrowserJetView: View {
    @Environment(\.appTheme)
    private var theme
    @Environment(\.designSystem)
    private var designSystem
    @Environment(\.colorScheme)
    private var colorScheme

    @State private var isLicenseKeyVisible = false
    @State private var licenseKeyCopyShowsCheckmark = false
    @State private var licenseKeyCopyResetTask: Task<Void, Never>?

    let model: AboutBrowserJetDisplayModel
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            headerView

            Divider().overlay(theme.divider)

            VStack(spacing: 18) {
                profileSection
                licenseSection

                if model.presentationStatus == .expired {
                    expiredWarningView
                }
            }
            .padding(24)

            Divider().overlay(theme.divider)

            footerView
        }
        .frame(width: 520)
        .brandThemedWindow()
    }

    private var headerView: some View {
        HStack(spacing: 14) {
            Image("ic_logo")
                .resizable()
                .scaledToFit()
                .frame(width: 46, height: 46)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text("About BrowserJet")
                    .font(designSystem.typography.heading4.font)
                    .foregroundStyle(theme.textPrimary)

                Text("Check your account and license details.")
                    .font(designSystem.typography.textBody1.font)
                    .foregroundStyle(theme.textFieldSecondary)
            }

            Spacer()
        }
        .padding(24)
    }

    private var profileSection: some View {
        sectionCard(title: "Profile") {
            infoRow(title: "Username", value: model.username)
            infoRow(title: "Email Address", value: model.email)
            infoRow(title: "Plan", value: model.planDisplayName) {
                statusBadge
            }
        }
    }

    private var licenseSection: some View {
        sectionCard(title: "License Information") {
            licenseKeyRow
            infoRow(title: "Licenses Purchased", value: "\(model.licensesPurchased)")
            infoRow(title: model.presentationStatus.expiryRowTitle, value: model.expiryDisplayText)
        }
    }

    private var licenseKeyRow: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("License Key")
                    .font(designSystem.typography.textCaption.font)
                    .foregroundStyle(theme.textFieldSecondary)

                Text(isLicenseKeyVisible ? model.licenseKey : maskedLicenseKey(model.licenseKey))
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundStyle(theme.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()

            HStack(spacing: 8) {
                Button {
                    copyLicenseKeyToPasteboard()
                } label: {
                    Image(systemName: licenseKeyCopyShowsCheckmark ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(licenseKeyCopyShowsCheckmark ? theme.vpnConnection : theme.accent)
                        .frame(width: 22, height: 22)
                        .contentTransition(.symbolEffect(.replace))
                }
                .buttonStyle(.plain)
                .help(licenseKeyCopyShowsCheckmark ? "Copied" : "Copy license key")
                .disabled(model.licenseKey.isEmpty)
                .opacity(model.licenseKey.isEmpty ? 0.4 : 1)

                Button {
                    isLicenseKeyVisible.toggle()
                } label: {
                    Image(systemName: isLicenseKeyVisible ? "eye.slash" : "eye")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(theme.accent)
                        .frame(width: 22, height: 22)
                }
                .buttonStyle(.plain)
                .help(isLicenseKeyVisible ? "Hide license key" : "Show license key")
            }
        }
    }

    private var statusBadge: some View {
        Text(model.presentationStatus.badgeTitle)
            .font(designSystem.typography.textCaption.font)
            .foregroundStyle(badgeForeground)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(badgeForeground.opacity(0.12)))
    }

    private var badgeForeground: Color {
        switch model.presentationStatus {
        case .active:
            return theme.vpnConnection
        case .trialActive:
            return theme.accent
        case .expired:
            return theme.danger
        }
    }

    private var expiredWarningView: some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(theme.danger)

            Text("Your license has expired. BrowserJet access may be limited until you renew or change your key.")
                .font(designSystem.typography.textBody1.font)
                .foregroundStyle(theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)

            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(theme.danger.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(theme.danger.opacity(0.18), lineWidth: 1)
        )
    }

    private var footerView: some View {
        HStack {
            Text(model.displayVersionLine)
                .font(designSystem.typography.textCaption.font)
                .foregroundStyle(theme.textFieldSecondary)

            Spacer()

            Button("Close") {
                onClose()
            }
            .keyboardShortcut(.cancelAction)
        }
        .padding(24)
    }

    private func sectionCard<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(designSystem.typography.heading4.font)
                .foregroundStyle(theme.textPrimary)

            VStack(spacing: 14) {
                content()
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(theme.surfaceCard)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(theme.strokeCard.opacity(0.6), lineWidth: 1)
        )
    }

    private func infoRow<Trailing: View>(
        title: String,
        value: String,
        @ViewBuilder trailing: () -> Trailing
    ) -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(designSystem.typography.textCaption.font)
                    .foregroundStyle(theme.textFieldSecondary)

                Text(value)
                    .font(designSystem.typography.textBody1.font.weight(.medium))
                    .foregroundStyle(theme.textPrimary)
                    .lineLimit(2)
                    .truncationMode(.middle)
            }

            Spacer()

            trailing()
        }
    }

    private func infoRow(title: String, value: String) -> some View {
        infoRow(title: title, value: value) {
            EmptyView()
        }
    }

    private func maskedLicenseKey(_ key: String) -> String {
        guard key.count > 10 else { return "••••••••" }

        let prefix = key.prefix(4)
        let suffix = key.suffix(5)

        return "\(prefix)••••••••••••••••\(suffix)"
    }

    private func copyLicenseKeyToPasteboard() {
        let key = model.licenseKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { return }

        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(key, forType: .string)

        licenseKeyCopyResetTask?.cancel()
        withAnimation(.easeInOut(duration: 0.12)) {
            licenseKeyCopyShowsCheckmark = true
        }

        licenseKeyCopyResetTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(550))
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: 0.12)) {
                licenseKeyCopyShowsCheckmark = false
            }
        }
    }
}
