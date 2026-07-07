//
//  ManageMyProxyRootView.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 07/07/2026.
//

import SwiftUI

private enum ManageMyProxyRootConstants {
    static let outerSpacing: CGFloat = 18
    static let tabPickerWidth: CGFloat = 320
}

struct ManageMyProxyRootView: View {
    @Environment(\.appTheme)
    private var theme
    @Environment(\.designSystem)
    private var designSystem

    @ObservedObject var viewModel: ManageMyProxyViewModel
    @ObservedObject private var repository = ManagedProxyRepository.shared

    private typealias Constants = ManageMyProxyRootConstants

    var body: some View {
        VStack(spacing: Constants.outerSpacing) {
            header
            tabPicker

            switch viewModel.selectedTab {
            case .manageProxies:
                ManageProxiesTabView(viewModel: viewModel)
            case .addProxies:
                AddProxiesTabView(viewModel: viewModel)
            }

            Spacer(minLength: 0)
        }
        .padding(DesignMetrics.screenPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(AppBackgroundStyle.brandGradient(for: .dark).makeView().ignoresSafeArea())
        .onAppear { viewModel.onAppear() }
        .onDisappear { viewModel.onDisappear() }
        .onChange(of: repository.groups) { _, newGroups in
            viewModel.handleGroupsChanged(newGroups)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(ManageMyProxyMessages.windowTitle)
                .font(designSystem.typography.title1.font)
                .foregroundStyle(theme.textPrimary)

            Text("Manage your own proxy groups, synced to your BrowserJet account.")
                .font(designSystem.typography.textBody2.font)
                .foregroundStyle(theme.textFieldSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var tabPicker: some View {
        BrowserJetSegmentedPicker(
            options: ManageMyProxyTab.allCases,
            selection: $viewModel.selectedTab,
            width: Constants.tabPickerWidth
        ) { $0.rawValue }
    }
}
