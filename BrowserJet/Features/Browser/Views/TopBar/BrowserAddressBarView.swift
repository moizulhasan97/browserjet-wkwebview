//
//  BrowserAddressBarView.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 17/02/2026.
//

import SwiftUI
import WebKit

struct BrowserAddressBarView: View {
    @Environment(\.designSystem)
    private var designSystem
    @Environment(\.appTheme)
    private var theme

    @ObservedObject var tab: TabModel
    /// When true (trial/license expired), bar shows URL but is read-only and visually disabled.
    var isLocked: Bool = false

    @State private var isHovering: Bool = false
    @FocusState private var isFocused: Bool

    private var leftIconName: String {
        if let url = tab.webView.url, let scheme = url.scheme?.lowercased() {
            return iconName(forScheme: scheme)
        }

        if let typedURL = URL(string: tab.addressText), let scheme = typedURL.scheme?.lowercased() {
            return iconName(forScheme: scheme)
        }

        return "globe"
    }

    private func iconName(forScheme scheme: String) -> String {
        switch scheme {
        case "https": return "lock.fill"
        case "http":  return "exclamationmark.triangle.fill"
        default:      return "globe"
        }
    }

    private var shouldShowClear: Bool {
        !isLocked && isFocused && !tab.addressText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var addressBinding: Binding<String> {
        if isLocked {
            return Binding(get: { tab.addressText }, set: { _ in })
        }
        return Binding(get: { tab.addressText }, set: { tab.addressText = $0 })
    }

    var body: some View {
        BrowserJetTextField(
            type: .browserAddress,
            text: addressBinding,
            placeholder: "Search or enter website",
            left: { leftIcon },
            right: { rightClearButton }
        )
        .environment(\.isEnabled, !isLocked)
        .clipShape(Capsule())
        .overlay(pillBorder)
        .allowsHitTesting(!isLocked)
        .onHover { hovering in
            guard !isLocked else { return }
            withAnimation(.easeInOut(duration: 0.12)) {
                isHovering = hovering
            }
        }
        .onTapGesture {
            guard !isLocked else { return }
            isFocused = true
        }
        .onSubmit {
            guard !isLocked else { return }
            tab.load(tab.addressText)
        }
    }

    private var leftIcon: some View {
        Image(systemName: leftIconName)
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(theme.textPrimary.opacity(0.8))
            .frame(width: 18, height: 18)
    }

    @ViewBuilder
    private var rightClearButton: some View {
        if shouldShowClear {
            Button {
                tab.addressText = ""
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(theme.textPrimary.opacity(0.45))
                    .padding(.trailing, 2)
            }
            .buttonStyle(.plain)
            .transition(.opacity.combined(with: .scale(scale: 0.9)))
        } else {
            EmptyView()
        }
    }

    private var pillBorder: some View {
        Capsule()
            .stroke(
                isHovering ? theme.strokeControl.opacity(0.9) : theme.strokeControl.opacity(0.65),
                lineWidth: DesignMetrics.controlStrokeWidth
            )
    }
}

#Preview {
    BrowserAddressBarViewPreviewHost()
        .padding()
        .background(AppBackgroundStyle.browserJetGradient.makeView())
        .environment(\.appTheme, BrowserJetLightTheme())
        .environment(\.designSystem, DesignSystem())
}

@MainActor
private final class PreviewTabHolder: ObservableObject {
    let tab: TabModel = TabModel.preview(
        addressText: "https://www.google.com",
        title: "Google",
        isLoading: false,
        favicon: nil
    )

    func setAddress(_ text: String) {
        tab.addressText = text
    }
}

private struct BrowserAddressBarViewPreviewHost: View {
    @StateObject private var holder = PreviewTabHolder()

    var body: some View {
        VStack(spacing: 16) {
            BrowserAddressBarView(tab: holder.tab)
                .frame(maxWidth: 900)

            HStack {
                Button("Set https") { holder.setAddress("https://www.google.com") }
                Button("Set http")  { holder.setAddress("http://example.com") }
                Button("Set query") { holder.setAddress("ticketmaster queue") }
            }
        }
    }
}
