//
//  BrowserJetSegmentedPicker.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 22/02/2026.
//

import SwiftUI

struct BrowserJetSegmentedPicker<Option: Hashable>: View {
    @Environment(\.appTheme)
    private var theme

    @Environment(\.isEnabled)
    private var isEnabled

    @Binding private var selection: Option

    private let options: [Option]
    private let isDisabled: Bool
    private let width: CGFloat?
    private let label: (Option) -> String

    init(
        options: [Option],
        selection: Binding<Option>,
        isDisabled: Bool = false,
        width: CGFloat? = nil,
        label: @escaping (Option) -> String
    ) {
        self.options = options
        self._selection = selection
        self.isDisabled = isDisabled
        self.width = width
        self.label = label
    }

    var body: some View {
        Picker("", selection: $selection) {
            ForEach(options, id: \.self) { option in
                Text(label(option))
                    .tag(option)
            }
        }
        .labelsHidden()
        .pickerStyle(.segmented)
        .disabled(isDisabled)
        .frame(width: width)
        .opacity((isEnabled && !isDisabled) ? 1 : 0.6)
        .tint(theme.accent) // ensures accent matches BrowserJet theme
    }
}

private enum ActivationMode: String, CaseIterable, Hashable {
    case activate = "Use Key"
    case register = "Register"
}

#Preview("Segmented Picker") {
    StatefulPreviewWrapper(ActivationMode.activate) { selection in
        BrowserJetSegmentedPicker(
            options: ActivationMode.allCases,
            selection: selection,
            width: 260
        ) { $0.rawValue }
        .padding()
        .environment(\.appTheme, BrowserJetLightTheme())
    }
}

struct StatefulPreviewWrapper<Value, Content: View>: View {
    @State private var value: Value
    private let content: (Binding<Value>) -> Content

    init(_ value: Value, content: @escaping (Binding<Value>) -> Content) {
        _value = State(initialValue: value)
        self.content = content
    }

    var body: some View {
        content($value)
    }
}
