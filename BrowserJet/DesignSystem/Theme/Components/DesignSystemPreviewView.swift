//
//  DesignSystemPreviewView.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 11/02/2026.
//

import SwiftUI

enum BackgroundPickerOption: String, CaseIterable, Hashable {
    case gradient
    case solid
}

struct DesignSystemPreviewView: View {
    @Environment(\.appTheme) private var theme
    @State private var backgroundOption: BackgroundPickerOption = .gradient

    private var background: AppBackgroundStyle {
        switch backgroundOption {
        case .gradient:
            return .browserJetGradient
        case .solid:
            return .solid(Color(nsColor: .windowBackgroundColor))
        }
    }
    @State private var disabled = false

    var body: some View {
        ZStack {
            background.makeView()
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: DesignMetrics.sectionSpacing) {

                HStack {
                    Text("Design System Preview")
                        .font(.system(size: 24, weight: .regular))
                        .foregroundStyle(theme.textPrimary)

                    Spacer()

                    Picker("", selection: $backgroundOption) {
                        Text("Gradient").tag(BackgroundPickerOption.gradient)
                        Text("Solid").tag(BackgroundPickerOption.solid)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 220)
                }

                VStack(alignment: .leading, spacing: DesignMetrics.rowSpacing) {

                    Text("Card / Surface")
                        .foregroundStyle(theme.textSecondary)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Welcome Gabriel")
                            .font(.system(size: 26, weight: .regular))
                            .foregroundStyle(theme.textPrimary)

                        HStack(spacing: 12) {
                            HStack(spacing: 10) {
                                Image(systemName: "magnifyingglass")
                                    .foregroundStyle(theme.textMuted)
                                Text("www.google.com")
                                    .foregroundStyle(theme.textMuted)
                                Spacer()
                            }
                            .glassControl(theme: theme)

                            Text("1")
                                .frame(width: 54)
                                .glassControl(theme: theme)
                        }

                        Divider().background(theme.divider)

                        HStack {
                            Text("Launch Button")
                                .foregroundStyle(theme.textSecondary)

                            Spacer()

                            Toggle("Disabled", isOn: $disabled)
                                .labelsHidden()
                        }

                        Button("Launch") {}
                            .frame(maxWidth: .infinity)
                            .frame(height: DesignMetrics.buttonHeight)
                            .background(disabled ? theme.accentDisabled : theme.accent)
                            .foregroundStyle(theme.textOnAccent)
                            .clipShape(Capsule())
                            .opacity(disabled ? 0.7 : 1.0)
                            .disabled(disabled)
                    }
                    .padding(DesignMetrics.cardPadding)
                    .glassCard(theme: theme)
                }

                Spacer()
            }
            .padding(DesignMetrics.screenPadding)
            .frame(minWidth: 860, minHeight: 720)
        }
    }
}

#Preview {
    // Provide a theme in preview if needed
    DesignSystemPreviewView()
        .environment(\.appTheme, BrowserJetLightTheme())
}
