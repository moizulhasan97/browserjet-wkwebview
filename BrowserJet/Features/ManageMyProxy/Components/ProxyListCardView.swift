//
//  ProxyListCardView.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 08/07/2026.
//

import SwiftUI

private enum ProxyListCardConstants {
    static let tableMaxHeight: CGFloat = 280
}

/// Main content area: search, a clean table, and row-level actions — independently scrollable
/// so the rest of the screen never needs to scroll just because a group has many proxies.
struct ProxyListCardView: View {
    @Environment(\.appTheme)
    private var theme
    @Environment(\.designSystem)
    private var designSystem

    @ObservedObject var viewModel: ManageMyProxyViewModel
    @ObservedObject private var repository = ManagedProxyRepository.shared

    private typealias Constants = ProxyListCardConstants

    var body: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 12) {
                titleRow
                searchField
                content
            }
        }
    }

    private var titleRow: some View {
        HStack {
            Text("Proxies in \(viewModel.selectedGroup?.name ?? "Group")")
                .font(designSystem.typography.heading4.font)
                .foregroundStyle(theme.textPrimary)

            Spacer()

            Button("Delete All") { viewModel.confirmDeleteAllProxies() }
                .buttonStyle(.plain)
                .font(designSystem.typography.textBody2.font)
                .foregroundStyle(theme.danger)
                .disabled(viewModel.proxiesInSelectedGroup.isEmpty)
        }
    }

    @ViewBuilder private var searchField: some View {
        if !viewModel.proxiesInSelectedGroup.isEmpty {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(theme.textFieldSecondary)
                TextField("Search IP, host or username…", text: $viewModel.searchText)
                    .textFieldStyle(.plain)
                    .foregroundStyle(theme.textPrimary)
                    .font(designSystem.typography.textBody2.font)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(theme.surfaceControl)
            .clipShape(RoundedRectangle(cornerRadius: DesignMetrics.controlCornerRadius, style: .continuous))
        }
    }

    @ViewBuilder private var content: some View {
        if repository.isLoadingGroups {
            Text(ManageMyProxyMessages.loadingProxies)
                .font(designSystem.typography.textBody2.font)
                .foregroundStyle(theme.textFieldSecondary)
        } else if viewModel.proxiesInSelectedGroup.isEmpty {
            emptyState
        } else if viewModel.filteredProxiesInSelectedGroup.isEmpty {
            Text("No proxies match \"\(viewModel.searchText)\".")
                .font(designSystem.typography.textBody2.font)
                .foregroundStyle(theme.textFieldSecondary)
        } else {
            tableHeader
            ScrollView {
                LazyVStack(spacing: 6) {
                    ForEach(viewModel.filteredProxiesInSelectedGroup) { proxy in
                        ManagedProxyRowView(
                            proxy: proxy,
                            isPasswordRevealed: viewModel.revealedProxyIDs.contains(proxy.id),
                            onToggleReveal: { viewModel.togglePasswordReveal(proxy) },
                            onDelete: { viewModel.confirmDeleteProxy(proxy) }
                        )
                    }
                }
            }
            .frame(maxHeight: Constants.tableMaxHeight)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "tray")
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(theme.textFieldSecondary)
            Text(ManageMyProxyMessages.emptyStateTitle)
                .font(designSystem.typography.textBody1.font)
                .foregroundStyle(theme.textPrimary)
            Text(ManageMyProxyMessages.emptyStateSubtitle)
                .font(designSystem.typography.textBody2.font)
                .foregroundStyle(theme.textFieldSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    private var tableHeader: some View {
        HStack(spacing: 12) {
            headerCell("Host", minWidth: 110)
            headerCell("Port", minWidth: 56)
            headerCell("Username", minWidth: 90)
            headerCell("Password", minWidth: 90)
            headerCell("Added", minWidth: 80)
            Spacer(minLength: 0)
            headerCell("Actions", minWidth: 60)
        }
    }

    private func headerCell(_ text: String, minWidth: CGFloat) -> some View {
        Text(text.uppercased())
            .font(designSystem.typography.textCaption.font)
            .foregroundStyle(theme.textFieldSecondary)
            .frame(minWidth: minWidth, alignment: .leading)
    }
}
