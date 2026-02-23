//
//  LauncherSearchField.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 11/02/2026.
//

import SwiftUI

struct LauncherSearchField: View {
    @Environment(\.designSystem)
    private var designSystem
    @Environment(\.appTheme)
    private var theme
    @Binding private var text: String
    private let placeholder: String = "Enter your address..."
    private let height: CGFloat = DesignMetrics.launcherAddressFieldHeight

    init(text: Binding<String>) {
        self._text = text
    }

    var body: some View {
        BrowserJetTextField(
            type: .launcherAddress,
            text: $text,
            placeholder: "Enter your address...",
            left: { Image(.icSearch) },
            right: { EmptyView() }
        )
    }

    private var searchIcon: some View {
        Image(.icSearch)
    }
}

#Preview {
    LauncherSearchField(text: .constant(""))
}
