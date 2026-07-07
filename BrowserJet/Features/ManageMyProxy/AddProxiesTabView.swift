//
//  AddProxiesTabView.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 07/07/2026.
//

import SwiftUI
import UniformTypeIdentifiers

private enum AddProxiesTabConstants {
    static let sectionSpacing: CGFloat = 16
    static let fieldSpacing: CGFloat = 12
    static let pickerWidth: CGFloat = 200
    static let tableMaxHeight: CGFloat = 220
}

struct AddProxiesTabView: View {
    @Environment(\.appTheme)
    private var theme
    @Environment(\.designSystem)
    private var designSystem
    
    @ObservedObject var viewModel: ManageMyProxyViewModel
    @ObservedObject private var repository = ManagedProxyRepository.shared
    
    private typealias Constants = AddProxiesTabConstants
    
    var body: some View {
        ScrollView {
            VStack(spacing: Constants.sectionSpacing) {
                selectGroupCard
                manualAddCard
                importExportCard
                proxyTableCard
            }
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
                viewModel.tableActionError = error.localizedDescription
            }
        }
        .fileExporter(
            isPresented: $viewModel.isExportPickerPresented,
            document: viewModel.exportDocument,
            contentType: .commaSeparatedText,
            defaultFilename: ManageMyProxyMessages.exportDefaultFileName
        ) { result in
            if case .failure(let error) = result {
                viewModel.tableActionError = error.localizedDescription
            }
        }
        .alert(
            ManageMyProxyMessages.importSummaryTitle,
            isPresented: Binding(
                get: { viewModel.importSummary != nil },
                set: { if !$0 { viewModel.importSummary = nil } }
            ),
            presenting: viewModel.importSummary
        ) { _ in
            Button("OK") { viewModel.importSummary = nil }
        } message: { summary in
            Text(summary.summaryMessage)
        }
        .alert(
            "Something went wrong",
            isPresented: Binding(
                get: { viewModel.tableActionError != nil },
                set: { if !$0 { viewModel.tableActionError = nil } }
            )
        ) {
            Button("OK") { viewModel.tableActionError = nil }
        } message: {
            Text(viewModel.tableActionError ?? "")
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
    }
    
    // MARK: - Select Group
    
    private var selectGroupCard: some View {
        CardContainer {
            HStack {
                Text("Select Group")
                    .foregroundStyle(theme.textPrimary)
                    .font(designSystem.typography.textBody1.font)
                Spacer()
                if repository.groups.isEmpty {
                    Text(ManageMyProxyMessages.noGroupsYet)
                        .font(designSystem.typography.textBody2.font)
                        .foregroundStyle(theme.textFieldSecondary)
                } else {
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
    }
    
    // MARK: - Manual add
    
    private var manualAddCard: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: Constants.sectionSpacing) {
                Text("Add Proxy")
                    .font(designSystem.typography.heading4.font)
                    .foregroundStyle(theme.textPrimary)
                
                HStack(spacing: Constants.fieldSpacing) {
                    BrowserJetTextField(
                        type: .activationField,
                        title: "IP / Host",
                        text: $viewModel.hostText,
                        placeholder: "203.0.113.10"
                    )
                    BrowserJetTextField(
                        type: .activationField,
                        title: "Port",
                        text: $viewModel.portText,
                        placeholder: "8080"
                    )
                }
                
                HStack(spacing: Constants.fieldSpacing) {
                    BrowserJetTextField(
                        type: .activationField,
                        title: "Username",
                        text: $viewModel.usernameText,
                        placeholder: "Required"
                    )
                    BrowserJetTextField(
                        type: .activationField,
                        title: "Password",
                        text: $viewModel.passwordText,
                        placeholder: "Required",
                        isSecure: true
                    )
                }
                
                BrowserJetAppButton(
                    title: viewModel.isAddingProxy ? "Adding…" : "Add Proxy",
                    type: .secondaryLarge,
                    isDisabled: viewModel.isAddingProxy || viewModel.selectedGroup == nil
                ) {
                    viewModel.submitAddProxy()
                }
                
                if let error = viewModel.addProxyError {
                    Text(error)
                        .font(designSystem.typography.textBody2.font)
                        .foregroundStyle(theme.danger)
                }
            }
        }
    }
    
    // MARK: - Import / Export
    
    private var importExportCard: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    BrowserJetAppButton(
                        title: viewModel.isImporting ? "Importing…" : "Load File",
                        type: .secondaryLarge,
                        isDisabled: viewModel.isImporting || viewModel.selectedGroup == nil
                    ) {
                        viewModel.isImportPickerPresented = true
                    }
                    
                    BrowserJetAppButton(
                        title: "Export Proxies",
                        type: .secondaryLarge,
                        isDisabled: viewModel.proxiesInSelectedGroup.isEmpty
                    ) {
                        viewModel.prepareExport()
                    }
                }
                
                Text(ManageMyProxyMessages.importFormatHint)
                    .font(designSystem.typography.textCaption.font)
                    .foregroundStyle(theme.textFieldSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
    
    // MARK: - Table
    
    private var proxyTableCard: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Proxies in Group")
                        .font(designSystem.typography.heading4.font)
                        .foregroundStyle(theme.textPrimary)
                    Spacer()
                    Button("Delete All") { viewModel.confirmDeleteAllProxies() }
                        .buttonStyle(.plain)
                        .font(designSystem.typography.textBody2.font)
                        .foregroundStyle(theme.danger)
                        .disabled(viewModel.proxiesInSelectedGroup.isEmpty)
                }
                
                if repository.isLoadingGroups {
                    Text(ManageMyProxyMessages.loadingProxies)
                        .font(designSystem.typography.textBody2.font)
                        .foregroundStyle(theme.textFieldSecondary)
                } else if viewModel.proxiesInSelectedGroup.isEmpty {
                    Text(ManageMyProxyMessages.noProxiesInGroup)
                        .font(designSystem.typography.textBody2.font)
                        .foregroundStyle(theme.textFieldSecondary)
                } else {
                    tableHeader
                    ScrollView {
                        LazyVStack(spacing: 6) {
                            ForEach(viewModel.proxiesInSelectedGroup) { proxy in
                                ManagedProxyRowView(
                                    groupName: viewModel.selectedGroup?.name ?? "",
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
        }
    }
    
    private var tableHeader: some View {
        HStack(spacing: 12) {
            headerCell("Group")
            headerCell("Host")
            headerCell("Port")
            headerCell("Username")
            headerCell("Password")
            Spacer(minLength: 0)
            headerCell("Actions")
        }
    }
    
    private func headerCell(_ text: String) -> some View {
        Text(text.uppercased())
            .font(designSystem.typography.textCaption.font)
            .foregroundStyle(theme.textFieldSecondary)
            .frame(minWidth: 56, alignment: .leading)
    }
}
