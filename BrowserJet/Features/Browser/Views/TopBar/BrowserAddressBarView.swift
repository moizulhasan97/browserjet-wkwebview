//
//  BrowserAddressBarView.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 17/02/2026.
//

import SwiftUI
import WebKit

struct BrowserAddressBarView: View {
    @Environment(\.designSystem) private var designSystem
    @Environment(\.appTheme) private var theme
    
    @ObservedObject var tab: TabModel
    
    private let height: CGFloat = DesignMetrics.browserAddressFieldHeight
    
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
        isFocused && !tab.addressText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        AddressFieldBase(
            text: Binding(
                get: { tab.addressText },
                set: { tab.addressText = $0 }
            ),
            placeholder: "Search or enter website",
            height: height,
            font: designSystem.typography.launcherField.font,
            fontColor: theme.textPrimary,
            left: { leftIcon },
            right: { rightClearButton }
        )
        .clipShape(Capsule())
        .overlay(pillBorder)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.12)) {
                isHovering = hovering
            }
        }
        .onTapGesture {
            isFocused = true
        }
        .onSubmit {
            tab.load(tab.addressText)
        }
    }
    
    private var leftIcon: some View {
        Image(systemName: leftIconName)
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(theme.textPrimary.opacity(0.8))
            .frame(width: 18, height: 18)
        //.padding(.leading, 2)
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

private struct BrowserAddressBarViewPreviewHost: View {
    @StateObject private var tab = MockTabModel()
    
    var body: some View {
        VStack(spacing: 16) {
            BrowserAddressBarView(tab: tab.asTabModel)
                .frame(maxWidth: 900)
            
            // quick controls to simulate editing
            HStack {
                Button("Set https") { tab.setAddress("https://www.google.com") }
                Button("Set http") { tab.setAddress("http://example.com") }
                Button("Set query") { tab.setAddress("ticketmaster queue") }
            }
        }
    }
}

/// A tiny preview helper so we don’t rely on a live WKWebView in Preview.
@MainActor
private final class MockTabModel: ObservableObject {
    @Published var addressText: String = "https://www.google.com"
    @Published var title: String = "Google"
    @Published var isLoading: Bool = false
    @Published var favicon: NSImage? = nil
    
    // Provide a real WKWebView instance (it exists in preview, but may not navigate).
    let webView: WKWebView = WKWebView()
    
    func setAddress(_ text: String) {
        addressText = text
    }
    
    var asTabModel: TabModel {
        TabModel.preview(
            addressText: addressText,
            title: title,
            isLoading: isLoading,
            favicon: favicon,
            webView: webView
        )
    }
}
