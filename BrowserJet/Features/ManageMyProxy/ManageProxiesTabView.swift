//
//  ManageProxiesTabView.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 07/07/2026.
//

import SwiftUI

private enum ManageProxiesTabConstants {
    static let sectionSpacing: CGFloat = 16
    static let pickerWidth: CGFloat = 200
    static let addGroupButtonWidth: CGFloat = 120
}

struct ManageProxiesTabView: View {
    @Environment(\.appTheme)
    private var theme
    @Environment(\.designSystem)
    private var designSystem
    
    @ObservedObject var viewModel: ManageMyProxyViewModel
    @ObservedObject private var repository = ManagedProxyRepository.shared
    
    private typealias Constants = ManageProxiesTabConstants
    
    var body: some View {
        ScrollView {
            VStack(spacing: Constants.sectionSpacing) {
                setUserProxyCard
                addGroupCard
                removeGroupCard
            }
        }
    }
    
    // MARK: - Set User Proxy
    
    private var setUserProxyCard: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: Constants.sectionSpacing) {
                Text("Set User Proxy")
                    .font(designSystem.typography.heading4.font)
                    .foregroundStyle(theme.textPrimary)
                
                groupPickerRow
                rotationRow
                BrowserJetDivider()
                useMyProxyButton
                
                if let footnote = viewModel.useMyProxyFootnote {
                    Text(footnote)
                        .font(designSystem.typography.textBody2.font)
                        .foregroundStyle(theme.textFieldSecondary)
                }
                
                if let error = viewModel.useMyProxyError {
                    Text(error)
                        .font(designSystem.typography.textBody2.font)
                        .foregroundStyle(theme.danger)
                }
            }
        }
    }
    
    @ViewBuilder private var groupPickerRow: some View {
        if repository.isLoadingGroups {
            statusRow(ManageMyProxyMessages.loadingGroups)
        } else if repository.groups.isEmpty {
            statusRow(ManageMyProxyMessages.noGroupsYet)
        } else {
            HStack {
                Text("Select Group")
                    .foregroundStyle(theme.textPrimary)
                    .font(designSystem.typography.textBody1.font)
                Spacer()
                BrowserJetMenuPicker(
                    options: repository.groups,
                    selection: Binding(
                        get: { viewModel.selectedGroup ?? repository.groups[0] },
                        set: { viewModel.selectGroup($0) }
                    ),
                    width: Constants.pickerWidth
                ) { $0.name }
            }
        }
    }
    
    private var rotationRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Set Rotation Method")
                .foregroundStyle(theme.textPrimary)
                .font(designSystem.typography.textBody1.font)

            // Rotation is a per-session choice, not a saved group property — it resets to
            // .linear every time this window opens and is only applied to the launcher when
            // "Use My Proxy" is tapped below.
            BrowserJetSegmentedPicker(
                options: viewModel.availableRotationMethods,
                selection: $viewModel.rotationSelection,
                isDisabled: viewModel.selectedGroup == nil
            ) { $0.displayName }
        }
    }

    private var useMyProxyButton: some View {
        BrowserJetAppButton(
            title: "Use My Proxy",
            type: .primaryLarge,
            isDisabled: !viewModel.canUseMyProxy
        ) {
            viewModel.useMyProxy()
        }
    }
    
    private func statusRow(_ message: String) -> some View {
        HStack {
            Text(message)
                .font(designSystem.typography.textBody2.font)
                .foregroundStyle(theme.textFieldSecondary)
            Spacer()
        }
    }
    
    // MARK: - Add Group
    
    private var addGroupCard: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: Constants.sectionSpacing) {
                Text("Add Group")
                    .font(designSystem.typography.heading4.font)
                    .foregroundStyle(theme.textPrimary)
                
                HStack(alignment: .top, spacing: 12) {
                    BrowserJetTextField(
                        type: .activationField,
                        title: "Group Name",
                        text: $viewModel.newGroupName,
                        placeholder: "e.g. Team A"
                    )
                    .onSubmit { viewModel.submitAddGroup() }
                    
                    BrowserJetAppButton(
                        title: viewModel.isAddingGroup ? "Adding…" : "Add Group",
                        type: .secondaryLarge,
                        width: .fixed(width: Int(Constants.addGroupButtonWidth)),
                        isDisabled: viewModel.isAddingGroup
                        || viewModel.newGroupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ) {
                        viewModel.submitAddGroup()
                    }
                    .padding(.top, 20)
                }
                
                if let error = viewModel.addGroupError {
                    Text(error)
                        .font(designSystem.typography.textBody2.font)
                        .foregroundStyle(theme.danger)
                }
            }
        }
    }
    
    // MARK: - Remove Group
    
    private var removeGroupCard: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: Constants.sectionSpacing) {
                Text("Remove Group")
                    .font(designSystem.typography.heading4.font)
                    .foregroundStyle(theme.textPrimary)
                
                groupPickerRow
                
                BrowserJetAppButton(
                    title: viewModel.isRemovingGroup ? "Removing…" : "Remove Group",
                    type: .destructivePrimaryLarge,
                    isDisabled: viewModel.selectedGroup == nil || viewModel.isRemovingGroup
                ) {
                    if let group = viewModel.selectedGroup {
                        viewModel.confirmRemoveGroup(group)
                    }
                }
                
                if let error = viewModel.removeGroupError {
                    Text(error)
                        .font(designSystem.typography.textBody2.font)
                        .foregroundStyle(theme.danger)
                }
            }
        }
        .confirmationDialog(
            "Remove \"\(viewModel.groupPendingRemoval?.name ?? "")\"?",
            isPresented: Binding(
                get: { viewModel.groupPendingRemoval != nil },
                set: { if !$0 { viewModel.groupPendingRemoval = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Remove Group", role: .destructive) {
                viewModel.performRemoveGroup()
            }
            Button("Cancel", role: .cancel) {
                viewModel.groupPendingRemoval = nil
            }
        } message: {
            Text("This deletes the group and all \(viewModel.selectedGroup?.proxyCount ?? 0) proxies inside it. This can't be undone.")
        }
    }
}
