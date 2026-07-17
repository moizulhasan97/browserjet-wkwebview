//
//  GroupHeaderCardView.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 08/07/2026.
//

import SwiftUI

private enum GroupHeaderCardConstants {
    static let pickerWidth: CGFloat = 200
    static let addButtonSize: CGFloat = 30
    static let useMyProxyButtonWidth: CGFloat = 140
    static let useMyProxyButtonHeight: CGFloat = 32
}

/// Entry point of the Manage My Proxy screen: which group is being managed, a quick summary of
/// it (proxy count, rotation), and the group-level actions (create, delete, activate).
struct GroupHeaderCardView: View {
    @Environment(\.appTheme)
    private var theme
    @Environment(\.designSystem)
    private var designSystem

    @ObservedObject var viewModel: ManageMyProxyViewModel
    @ObservedObject private var repository = ManagedProxyRepository.shared

    private typealias Constants = GroupHeaderCardConstants

    var body: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 14) {
                selectorRow
                if !repository.groups.isEmpty {
                    badgesRow
                }
            }
        }
    }

    @ViewBuilder private var selectorRow: some View {
        HStack(spacing: 10) {
            Text("Select Group")
                .font(designSystem.typography.textBody1.font)
                .foregroundStyle(theme.textPrimary)

            Spacer()

            if repository.isLoadingGroups {
                Text(ManageMyProxyMessages.loadingGroups)
                    .font(designSystem.typography.textBody2.font)
                    .foregroundStyle(theme.textFieldSecondary)
            } else if let currentGroup = viewModel.selectedGroup ?? repository.groups.first {
                // `currentGroup` is a captured value snapshot, not a live subscript — the
                // Picker's `get` can be invoked by AppKit slightly out of step with this body's
                // own re-render (e.g. right after a group/proxy write causes the Firestore
                // listener to refire), so falling back to `repository.groups[0]` inside `get`
                // could momentarily read an empty array and crash. Falling back to `currentGroup`
                // instead can never do that.
                BrowserJetMenuPicker(
                    options: repository.groups,
                    selection: Binding(
                        get: { viewModel.selectedGroup ?? repository.groups.first ?? currentGroup },
                        set: { viewModel.selectGroup($0) }
                    ),
                    width: Constants.pickerWidth
                ) { $0.name }

                deleteGroupButton
            } else {
                Text(ManageMyProxyMessages.noGroupsYet)
                    .font(designSystem.typography.textBody2.font)
                    .foregroundStyle(theme.textFieldSecondary)
            }

            addGroupButton
        }
    }

    private var deleteGroupButton: some View {
        Button {
            guard let group = viewModel.selectedGroup ?? repository.groups.first else { return }
            viewModel.confirmRemoveGroup(group)
        } label: {
            Image(systemName: "trash")
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(theme.danger)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Delete group")
    }

    private var addGroupButton: some View {
        Button {
            viewModel.isAddGroupPopoverPresented = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(theme.textPrimary)
                .frame(width: Constants.addButtonSize, height: Constants.addButtonSize)
                .background(theme.surfaceControl)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add group")
        .popover(isPresented: $viewModel.isAddGroupPopoverPresented, arrowEdge: .bottom) {
            AddGroupPopoverView(viewModel: viewModel)
        }
    }

    private var badgesRow: some View {
        HStack(spacing: 10) {
            badge(icon: "chart.bar.fill", text: "\(viewModel.selectedGroup?.proxyCount ?? 0) proxies")

            Button {
                viewModel.cycleRotation()
            } label: {
                badge(icon: "arrow.triangle.2.circlepath", text: "\(viewModel.rotationSelection.displayName) rotation")
            }
            .buttonStyle(.plain)
            .disabled(viewModel.availableRotationMethods.count <= 1)

            Spacer()

            BrowserJetAppButton(
                title: "Use My Proxy",
                type: .secondaryLarge,
                width: .fixed(width: Int(Constants.useMyProxyButtonWidth)),
                height: Constants.useMyProxyButtonHeight,
                isDisabled: !viewModel.canUseMyProxy
            ) {
                viewModel.useMyProxy()
            }
        }
    }

    private func badge(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
            Text(text)
                .font(designSystem.typography.textCaption.font)
        }
        .foregroundStyle(theme.badgeText)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(theme.badgeBackground)
        .clipShape(Capsule())
    }
}
