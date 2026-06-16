//
//  BrowserJetMenuPicker.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 11/02/2026.
//

import SwiftUI

struct BrowserJetMenuPicker<Option: Hashable>: View {
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
                    .foregroundStyle(theme.textPrimary)
                    .tag(option)
            }
        }
        .labelsHidden()
        .pickerStyle(.menu)
        .disabled(isDisabled)
        .frame(width: width, alignment: .trailing)
        .opacity((isEnabled && !isDisabled) ? 1 : 0.6)
    }
}

#Preview {
    BrowserJetMenuPicker(
        options: VPNType.allCases,
        selection: .constant(.vpn1),
        isDisabled: false,
        width: 110
    ) { $0.rawValue }
}
