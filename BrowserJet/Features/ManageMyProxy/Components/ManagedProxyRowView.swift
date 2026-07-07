//
//  ManagedProxyRowView.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 07/07/2026.
//


import SwiftUI

struct ManagedProxyRowView: View {
    @Environment(\.appTheme)
    private var theme
    @Environment(\.designSystem)
    private var designSystem

    let groupName: String
    let proxy: ManagedProxy
    let isPasswordRevealed: Bool
    let onToggleReveal: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            cell(groupName)
            cell(proxy.host)
            cell(String(proxy.port))
            cell(proxy.username)
            passwordCell
            Spacer(minLength: 0)
            deleteButton
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 6)
        .background(theme.surfaceControl.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func cell(_ text: String) -> some View {
        Text(text)
            .font(designSystem.typography.textBody2.font)
            .foregroundStyle(theme.textPrimary)
            .lineLimit(1)
            .frame(minWidth: 56, alignment: .leading)
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

    private var deleteButton: some View {
        Button(action: onDelete) {
            Image(systemName: "trash")
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(theme.danger)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Delete proxy")
    }
}