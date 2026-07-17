//
//  AddProxyFormCardView.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 08/07/2026.
//

import SwiftUI

private enum AddProxyFormConstants {
    static let columnSpacing: CGFloat = 16
    static let fieldSpacing: CGFloat = 12
}

/// The primary action on the screen: a compact two-column form (Host/Username left,
/// Port/Password right) with full keyboard support — autofocus on the Host field, Tab/Shift+Tab
/// across all four fields (native macOS key-view-loop behavior, no extra code needed), and
/// Enter-to-submit once the form validates.
struct AddProxyFormCardView: View {
    @Environment(\.appTheme)
    private var theme
    @Environment(\.designSystem)
    private var designSystem

    @ObservedObject var viewModel: ManageMyProxyViewModel
    var isHostFieldFocused: FocusState<Bool>.Binding

    private typealias Constants = AddProxyFormConstants

    var body: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 16) {
                Text("Add Proxy")
                    .font(designSystem.typography.heading4.font)
                    .foregroundStyle(theme.textPrimary)

                HStack(alignment: .top, spacing: Constants.columnSpacing) {
                    VStack(alignment: .leading, spacing: Constants.fieldSpacing) {
                        BrowserJetTextField(
                            type: .activationField,
                            title: "IP / Host",
                            text: $viewModel.hostText,
                            placeholder: "203.0.113.10",
                            rule: .requiredField,
                            focusBinding: isHostFieldFocused
                        )
                        BrowserJetTextField(
                            type: .activationField,
                            title: "Username",
                            text: $viewModel.usernameText,
                            placeholder: "e.g. myuser",
                            rule: .requiredField
                        )
                    }

                    VStack(alignment: .leading, spacing: Constants.fieldSpacing) {
                        BrowserJetTextField(
                            type: .activationField,
                            title: "Port",
                            text: $viewModel.portText,
                            placeholder: "8080",
                            rule: .proxyPort
                        )
                        BrowserJetTextField(
                            type: .activationField,
                            title: "Password",
                            text: $viewModel.passwordText,
                            placeholder: "e.g. mypass",
                            isSecure: true,
                            rule: .requiredField
                        )
                    }
                }
                .onSubmit {
                    if viewModel.canSubmitAddProxy {
                        viewModel.submitAddProxy()
                    }
                }

                BrowserJetAppButton(
                    title: viewModel.isAddingProxy ? "Adding…" : "Add Proxy",
                    type: .primaryLarge,
                    isDisabled: !viewModel.canSubmitAddProxy
                ) {
                    viewModel.submitAddProxy()
                }
            }
        }
    }
}
