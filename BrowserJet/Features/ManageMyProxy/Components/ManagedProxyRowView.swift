//
//  ManagedProxyRowView.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 07/07/2026.
//

import AppKit
import SwiftUI

struct ManagedProxyRowView: View {
    @Environment(\.appTheme)
    private var theme
    @Environment(\.designSystem)
    private var designSystem

    let proxy: ManagedProxy
    let isPasswordRevealed: Bool
    let onToggleReveal: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            cell(proxy.host, minWidth: 110)
            cell(String(proxy.port), minWidth: 56)
            cell(proxy.username, minWidth: 90)
            passwordCell
            Text(addedLabel)
                .font(designSystem.typography.textBody2.font)
                .foregroundStyle(theme.textFieldSecondary)
                .lineLimit(1)
                .frame(minWidth: 80, alignment: .leading)
            Spacer(minLength: 0)
            actionButtons
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(theme.surfaceControl.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func cell(_ text: String, minWidth: CGFloat) -> some View {
        Text(text)
            .font(designSystem.typography.textBody2.font)
            .foregroundStyle(theme.textPrimary)
            .lineLimit(1)
            .frame(minWidth: minWidth, alignment: .leading)
    }

    private var passwordCell: some View {
        HStack(spacing: 6) {
            Text(isPasswordRevealed ? proxy.password : String(repeating: "•", count: max(6, proxy.password.count)))
                .font(designSystem.typography.textBody2.font)
                .foregroundStyle(theme.textPrimary)
                .lineLimit(1)

            Button(action: onToggleReveal) {
                Image(systemName: isPasswordRevealed ? "eye.slash" : "eye")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(theme.textPrimary.opacity(0.6))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isPasswordRevealed ? "Hide password" : "Show password")
        }
        .frame(minWidth: 90, alignment: .leading)
    }

    private var actionButtons: some View {
        HStack(spacing: 10) {
            Button(action: copyToClipboard) {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(theme.textPrimary.opacity(0.6))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Copy proxy")

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(theme.danger)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Delete proxy")
        }
    }

    private var addedLabel: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: proxy.createdAt, relativeTo: Date())
    }

    private func copyToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString("\(proxy.host):\(proxy.port):\(proxy.username):\(proxy.password)", forType: .string)
    }
}
