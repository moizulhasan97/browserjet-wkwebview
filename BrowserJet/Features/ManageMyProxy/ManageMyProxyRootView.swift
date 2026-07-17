//
//  ManageMyProxyRootView.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 07/07/2026.
//

import SwiftUI
import UniformTypeIdentifiers

/// Single, unified screen (no tabs) — group selection, add proxy, import/export, and the proxy
/// list all live here in one macOS-native pass, per the redesign: minimize interaction, reduce
/// scrolling, make the primary action (Add Proxy) obvious.
struct ManageMyProxyRootView: View {
    @Environment(\.appTheme)
    private var theme
    @Environment(\.designSystem)
    private var designSystem

    @ObservedObject var viewModel: ManageMyProxyViewModel
    @ObservedObject private var repository = ManagedProxyRepository.shared

    @FocusState private var isHostFieldFocused: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: DesignMetrics.sectionSpacing) {
                header
                GroupHeaderCardView(viewModel: viewModel)
                AddProxyFormCardView(viewModel: viewModel, isHostFieldFocused: $isHostFieldFocused)
                ImportExportCardView(viewModel: viewModel)
                ProxyListCardView(viewModel: viewModel)
            }
            .padding(DesignMetrics.screenPadding)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(AppBackgroundStyle.brandGradient(for: .dark).makeView().ignoresSafeArea())
        .browserJetToast($viewModel.toast)
        .onAppear {
            viewModel.onAppear()
            isHostFieldFocused = true
        }
        .onDisappear { viewModel.onDisappear() }
        .onChange(of: repository.groups) { _, newGroups in
            viewModel.handleGroupsChanged(newGroups)
        }
        .onChange(of: viewModel.refocusHostFieldToken) { _, _ in
            isHostFieldFocused = true
        }
        .fileImporter(
            isPresented: $viewModel.isImportPickerPresented,
            allowedContentTypes: [.commaSeparatedText, .plainText],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    viewModel.importFile(at: url)
                }
            case .failure(let error):
                viewModel.toast = ToastMessage(text: error.localizedDescription, style: .error)
            }
        }
        .fileExporter(
            isPresented: $viewModel.isExportPickerPresented,
            document: viewModel.exportDocument,
            contentType: .commaSeparatedText,
            defaultFilename: ManageMyProxyMessages.exportDefaultFileName
        ) { result in
            viewModel.handleExportResult(result)
        }
        .confirmationDialog(
            "Delete this proxy?",
            isPresented: Binding(
                get: { viewModel.proxyPendingDeletion != nil },
                set: { if !$0 { viewModel.proxyPendingDeletion = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) { viewModel.performDeleteProxy() }
            Button("Cancel", role: .cancel) { viewModel.proxyPendingDeletion = nil }
        }
        .confirmationDialog(
            "Delete all proxies in this group?",
            isPresented: $viewModel.isDeleteAllConfirmationPresented,
            titleVisibility: .visible
        ) {
            Button("Delete All", role: .destructive) { viewModel.performDeleteAllProxies() }
            Button("Cancel", role: .cancel) { viewModel.isDeleteAllConfirmationPresented = false }
        }
        .confirmationDialog(
            "Remove \"\(viewModel.groupPendingRemoval?.name ?? "")\"?",
            isPresented: Binding(
                get: { viewModel.groupPendingRemoval != nil },
                set: { if !$0 { viewModel.groupPendingRemoval = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Remove Group", role: .destructive) { viewModel.performRemoveGroup() }
            Button("Cancel", role: .cancel) { viewModel.groupPendingRemoval = nil }
        } message: {
            Text("This deletes the group and all \(viewModel.groupPendingRemoval?.proxyCount ?? 0) proxies inside it. This can't be undone.")
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
}
