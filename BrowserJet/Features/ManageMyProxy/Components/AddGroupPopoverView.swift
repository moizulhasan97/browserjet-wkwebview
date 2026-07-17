//
//  AddGroupPopoverView.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 08/07/2026.
//

import SwiftUI

/// Lightweight "create group" form presented from the "+" button next to the group selector —
/// intentionally not a full card, per the redesign's goal of keeping group creation a quick,
/// secondary action rather than a dedicated section of the screen.
struct AddGroupPopoverView: View {
    @Environment(\.appTheme)
    private var theme
    @Environment(\.designSystem)
    private var designSystem

    @ObservedObject var viewModel: ManageMyProxyViewModel
    @FocusState private var isNameFieldFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("New Group")
                .font(designSystem.typography.heading4.font)
                .foregroundStyle(theme.textPrimary)

            BrowserJetTextField(
                type: .activationField,
                title: "Group Name",
                text: $viewModel.newGroupName,
                placeholder: "e.g. Residential Proxies",
                rule: .requiredField,
                focusBinding: $isNameFieldFocused
            )
            .onSubmit { viewModel.submitAddGroup() }

            BrowserJetAppButton(
                title: viewModel.isAddingGroup ? "Creating…" : "Create Group",
                type: .primaryLarge,
                isDisabled: viewModel.isAddingGroup
                    || viewModel.newGroupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ) {
                viewModel.submitAddGroup()
            }
        }
        .padding(18)
        .frame(width: 280)
        .onAppear { isNameFieldFocused = true }
    }
}
