//
//  BrowserJetTextField.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 23/02/2026.
//

import SwiftUI

// MARK: - TextField Type
enum BrowserJetTextFieldType: Equatable {
    case launcherAddress
    case browserAddress
    case activationField
}

struct BrowserJetTextField<Left: View, Right: View>: View {
    @Environment(\.designSystem)
    private var designSystem
    @Environment(\.appTheme)
    private var theme
    @Environment(\.isEnabled)
    private var isEnabled

    @FocusState private var isFocused: Bool
    @State private var isRevealed: Bool = false

    // MARK: - Public Config

    let type: BrowserJetTextFieldType
    let title: String?
    let titleSpacing: CGFloat
    let placeholder: String
    @Binding var text: String

    /// Renders the field as a secure (password) input with a show/hide toggle.
    let isSecure: Bool

    /// When provided, shows a validity indicator inside the field and a failure
    /// message below it when the text doesn't match.
    let rule: ValidationRule?

    /// Bind this to a property on view model to react to validity changes
    var validationState: Binding<RegexValidationState>?

    let left: () -> Left
    let right: () -> Right

    // MARK: - Init

    init(
        type: BrowserJetTextFieldType,
        title: String? = nil,
        titleSpacing: CGFloat = 6,
        text: Binding<String>,
        placeholder: String,
        isSecure: Bool = false,
        rule: ValidationRule? = nil,
        validationState: Binding<RegexValidationState>? = nil,
        @ViewBuilder left: @escaping () -> Left = { EmptyView() },
        @ViewBuilder right: @escaping () -> Right = { EmptyView() }
    ) {
        self.type = type
        self.title = title
        self.titleSpacing = titleSpacing
        self._text = text
        self.placeholder = placeholder
        self.isSecure = isSecure
        self.rule = rule
        self.validationState = validationState
        self.left = left
        self.right = right
    }

    // MARK: - Validation

    /// Current validation state derived from the rule and text.
    private var currentValidationState: RegexValidationState {
        rule?.evaluate(text) ?? .none
    }

    // MARK: - Body

    var body: some View {
        let style = designSystem.textFieldStyle.style(
            for: type,
            typography: designSystem.typography,
            viewConfig: designSystem.viewConfig,
            theme: theme
        )

        VStack(alignment: .leading, spacing: title == nil ? 0 : titleSpacing) {
            if let title {
                Text(title)
                    .font(designSystem.typography.textBody1.font)
                    .foregroundStyle(theme.textPrimary)
            }

            AddressFieldBase(
                text: $text,
                placeholder: placeholder,
                height: style.height,
                font: style.font,
                fontColor: isEnabled ? style.textColor : style.textDisabledColor,
                isSecure: isSecure && !isRevealed,
                left: left
            ) {
                HStack(spacing: 6) {
                    right()
                    validationIndicator
                    if isSecure {
                        revealToggle
                    }
                }
            }
            .padding(style.contentInsets)
            .background(background(for: style))
            .overlay(border(for: style))
            .clipShape(CornerRadiusShape(cornerRadius: style.cornerRadius))
            .focused($isFocused)
            .animation(.easeInOut(duration: 0.15), value: currentValidationState)
            .onChange(of: text) { _ in
                validationState?.wrappedValue = currentValidationState
            }

            // Inline failure message — only shown when text is actively wrong
            if currentValidationState == .invalid, let message = rule?.defaultMessage, !message.isEmpty {
                Text(message)
                    .font(designSystem.typography.textBody2.font.leading(.tight))
                    .foregroundStyle(theme.danger)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.15), value: currentValidationState)
    }

    // MARK: - Reveal Toggle

    private var revealToggle: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                isRevealed.toggle()
            }
        } label: {
            Image(systemName: isRevealed ? "eye.slash" : "eye")
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(theme.textPrimary.opacity(isRevealed ? 0.7 : 0.4))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isRevealed ? "Hide password" : "Show password")
    }

    // MARK: - Validation Indicator

    @ViewBuilder private var validationIndicator: some View {
        switch currentValidationState {
        case .valid:
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.green)
                .transition(.opacity.combined(with: .scale(scale: 0.85)))

        case .invalid:
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(theme.danger)
                .transition(.opacity.combined(with: .scale(scale: 0.85)))

        case .empty, .none:
            EmptyView()
        }
    }

    // MARK: - Styling

    private func background(for style: any BrowserJetTextFieldStyleProtocol) -> some View {
        let backgroundColor = isEnabled ? style.backgroundColor : style.backgroundDisabledColor
        return CornerRadiusShape(cornerRadius: style.cornerRadius).fill(backgroundColor)
    }

    private func border(for style: any BrowserJetTextFieldStyleProtocol) -> some View {
        let stroke: Color = {
            guard isEnabled else { return style.borderDisabledColor }
            switch currentValidationState {
            case .valid:   return .green.opacity(0.6)
            case .invalid: return theme.danger.opacity(0.6)
            default:
                return isFocused ? style.borderHighlightedColor : style.borderColor
            }
        }()
        return CornerRadiusShape(cornerRadius: style.cornerRadius)
            .stroke(stroke, lineWidth: style.borderWidth)
    }
}

// MARK: - CornerRadiusShape

private struct CornerRadiusShape: InsettableShape {
    let cornerRadius: CornerRadius
    var insetAmount: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        switch cornerRadius {
        case .fixed(let radius):
            return RoundedRectangle(cornerRadius: max(0, radius - insetAmount), style: .continuous).path(in: rect)
        case .capsule:
            return Capsule().path(in: rect)
        }
    }

    func inset(by amount: CGFloat) -> some InsettableShape {
        var copy = self
        copy.insetAmount += amount
        return copy
    }
}

// MARK: - Preview

#Preview("BrowserJetTextField") {
    TextFieldPreviewHost()
        .padding()
        .background(AppBackgroundStyle.browserJetGradient.makeView())
        .environment(\.appTheme, BrowserJetLightTheme())
        .environment(\.designSystem, DesignSystem())
}

private struct TextFieldPreviewHost: View {
    @State private var address = "https://www.google.com"
    @State private var licenseKey = ""
    @State private var email = "user@example"
    @State private var password = "secret1"

    var body: some View {
        VStack(spacing: 20) {
            BrowserJetTextField(
                type: .launcherAddress,
                title: "Address",
                text: $address,
                placeholder: "Enter your address..."
            )

            BrowserJetTextField(
                type: .activationField,
                title: "License Key",
                text: $licenseKey,
                placeholder: "XXXX-XXXX-XXXX",
                rule: .licenseKey
            )

            BrowserJetTextField(
                type: .activationField,
                title: "Email",
                text: $email,
                placeholder: "you@example.com",
                rule: .email
            )

            BrowserJetTextField(
                type: .activationField,
                title: "Password",
                text: $password,
                placeholder: "Enter password",
                isSecure: true,
                rule: .password
            )
        }
        .frame(width: 520)
    }
}
