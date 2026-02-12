//
//  AddressFieldBase.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 11/02/2026.
//

import SwiftUI

struct AddressFieldBase<Left: View, Right: View>: View {
    @Environment(\.appTheme)
    private var theme
    @Environment(\.designSystem)
    private var designSystem
    @FocusState private var isFocused: Bool
    private let text: Binding<String>
    private let placeholder: String
    private let height: CGFloat
    private let font: Font
    private let fontColor: Color
    private let left: Left
    private let right: Right

    init(
        text: Binding<String>,
        placeholder: String,
        height: CGFloat = DesignMetrics.launcherAddressFieldHeight,
        font: Font,
        fontColor: Color,
        @ViewBuilder left: () -> Left,
        @ViewBuilder right: () -> Right
    ) {
        self.text = text
        self.placeholder = placeholder
        self.height = height
        self.font = font
        self.fontColor = fontColor
        self.left = left()
        self.right = right()
    }

    var body: some View {
        HStack {
            left // icon

            textField

            right
        }
        .padding(.horizontal)
        .frame(height: height)
        .background(theme.surfaceControl)
        .overlay(
            RoundedRectangle(
                cornerRadius: DesignMetrics.controlCornerRadius,
                style: .continuous
            )
            .stroke(
                isFocused ? theme.accent.opacity(0.35) : theme.strokeControl,
                lineWidth: DesignMetrics.controlStrokeWidth
            )
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: DesignMetrics.controlCornerRadius,
                style: .continuous
            )
        )
    }

    private var textField: some View {
        ZStack(alignment: .leading) {
            if text.wrappedValue.isEmpty {
                Text(placeholder)
                    .foregroundStyle(theme.textFieldSecondary)
                    .font(font)
            }
            TextField("", text: text)
                .textFieldStyle(.plain)
                .font(font)
                .foregroundStyle(fontColor)
                .focused($isFocused)
        }
    }
}

#Preview {
    AddressFieldBase(
        text: .constant("https://www.google.com"),
        placeholder: "Enter adddress",
        height: 48.0,
        font: .system(size: 16, weight: .light),
        fontColor: .gray
    ) {
    } right: {
    }
}
