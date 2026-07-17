//
//  BrowserJetToast.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 08/07/2026.
//

import SwiftUI

/// Lightweight, auto-dismissing feedback bubble — shared alternative to native `.alert()` for
/// low-stakes confirmations ("Proxy added", "Export complete", etc.). Reusable via
/// `.browserJetToast(_:)`; not specific to any one feature.
struct ToastMessage: Identifiable, Equatable {
    enum Style {
        case success
        case error
    }

    let id = UUID()
    let text: String
    var style: Style = .success
}

private enum ToastConstants {
    static let autoDismissNanoseconds: UInt64 = 2_600_000_000
    static let horizontalPadding: CGFloat = 16
    static let verticalPadding: CGFloat = 12
    static let bottomInset: CGFloat = 20
}

struct BrowserJetToastView: View {
    @Environment(\.appTheme)
    private var theme
    @Environment(\.designSystem)
    private var designSystem

    let message: ToastMessage

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: message.style == .success ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(message.style == .success ? .green : theme.danger)

            Text(message.text)
                .font(designSystem.typography.textBody2.font)
                .foregroundStyle(theme.textPrimary)
                .lineLimit(2)
        }
        .padding(.horizontal, ToastConstants.horizontalPadding)
        .padding(.vertical, ToastConstants.verticalPadding)
        .background(theme.surfaceCardOverlay)
        .overlay(
            RoundedRectangle(cornerRadius: DesignMetrics.controlCornerRadius, style: .continuous)
                .stroke(theme.strokeCard, lineWidth: DesignMetrics.cardStrokeWidth)
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignMetrics.controlCornerRadius, style: .continuous))
        .shadow(color: .black.opacity(0.25), radius: 16, x: 0, y: 6)
    }
}

private struct BrowserJetToastModifier: ViewModifier {
    @Binding var message: ToastMessage?

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if let message {
                    BrowserJetToastView(message: message)
                        .padding(.bottom, ToastConstants.bottomInset)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .task(id: message.id) {
                            try? await Task.sleep(nanoseconds: ToastConstants.autoDismissNanoseconds)
                            guard !Task.isCancelled else { return }
                            withAnimation(.easeInOut(duration: 0.2)) { self.message = nil }
                        }
                }
            }
            .animation(.easeInOut(duration: 0.2), value: message)
    }
}

extension View {
    /// Overlays a bottom-anchored, auto-dismissing toast whenever `message` is non-nil.
    /// Setting a new value while one is showing replaces it and restarts the dismiss timer.
    func browserJetToast(_ message: Binding<ToastMessage?>) -> some View {
        modifier(BrowserJetToastModifier(message: message))
    }
}
