//
//  ManageMyProxyViewModel.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 07/07/2026.
//

import Combine
import Foundation

@MainActor
final class ManageMyProxyViewModel: ObservableObject {
    // MARK: - Tab / selection
    
    @Published var selectedTab: ManageMyProxyTab = .manageProxies
    @Published var selectedGroupID: String?
    /// Rotation is a per-session choice, not a saved group property — it always starts at
    /// `.linear` when this view model is created (i.e. every time the window is opened) and is
    /// only applied to the launcher when "Use My Proxy" is tapped. See the discussion in this
    /// conversation for why this isn't persisted to Firestore.
    @Published var rotationSelection: ProxyRotationType = .linear
    
    // MARK: - Add Group
    
    @Published var newGroupName: String = ""
    @Published var addGroupError: String?
    @Published var isAddingGroup: Bool = false
    
    // MARK: - Remove Group
    
    @Published var groupPendingRemoval: ProxyGroup?
    @Published var removeGroupError: String?
    @Published var isRemovingGroup: Bool = false
    
    // MARK: - Add Proxy (manual)
    
    @Published var hostText: String = ""
    @Published var portText: String = ""
    @Published var usernameText: String = ""
    @Published var passwordText: String = ""
    @Published var addProxyError: String?
    @Published var isAddingProxy: Bool = false
    
    // MARK: - Proxy table
    
    @Published var revealedProxyIDs: Set<String> = []
    @Published var proxyPendingDeletion: ManagedProxy?
    @Published var isDeleteAllConfirmationPresented: Bool = false
    @Published var tableActionError: String?
    
    // MARK: - Import / Export
    
    @Published var isImportPickerPresented: Bool = false
    @Published var isExportPickerPresented: Bool = false
    @Published var importSummary: ProxyImportSummary?
    @Published var isImporting: Bool = false
    @Published var exportDocument: ProxyExportDocument?
    
    // MARK: - Use My Proxy
    
    @Published var useMyProxyError: String?
    
    // MARK: - Dependencies
    
    let repository: ManagedProxyRepository
    private let onCustomProxyActivated: (ProxyGroup, ProxyRotationType) -> Void

    init(
        repository: ManagedProxyRepository = .shared,
        onCustomProxyActivated: @escaping (ProxyGroup, ProxyRotationType) -> Void
    ) {
        self.repository = repository
        self.onCustomProxyActivated = onCustomProxyActivated
    }
    
    // MARK: - Derived state
    
    var selectedGroup: ProxyGroup? {
        guard let selectedGroupID else { return nil }
        return repository.groups.first { $0.id == selectedGroupID }
    }
    
    var proxiesInSelectedGroup: [ManagedProxy] {
        guard let selectedGroupID else { return [] }
        return repository.proxies(inGroupID: selectedGroupID)
    }
    
    var availableRotationMethods: [ProxyRotationType] {
        ManageMyProxyAvailability.availableRotationMethods
    }
    
    var canUseMyProxy: Bool {
        !repository.isLoadingGroups
        && selectedGroup != nil
        && !proxiesInSelectedGroup.isEmpty
    }
    
    var useMyProxyFootnote: String? {
        if repository.isLoadingGroups { return ManageMyProxyMessages.useMyProxyLoadingData }
        if selectedGroup == nil { return ManageMyProxyMessages.useMyProxyNeedsGroup }
        if proxiesInSelectedGroup.isEmpty { return ManageMyProxyMessages.useMyProxyNeedsGroup }
        return nil
    }
    
    // MARK: - Lifecycle
    
    func onAppear() {
        repository.startManaging()
        AnalyticsManager.shared.log(.manageMyProxyOpened)
    }
    
    func onDisappear() {
        if let selectedGroupID {
            repository.stopObservingProxies(groupId: selectedGroupID)
        }
        repository.stopManaging()
    }
    
    func handleGroupsChanged(_ groups: [ProxyGroup]) {
        guard !groups.isEmpty else {
            selectedGroupID = nil
            return
        }
        if let selectedGroupID, groups.contains(where: { $0.id == selectedGroupID }) {
            return
        }
        selectGroup(groups[0])
    }
    
    func selectGroup(_ group: ProxyGroup) {
        if let previous = selectedGroupID, previous != group.id {
            repository.stopObservingProxies(groupId: previous)
        }
        selectedGroupID = group.id
        repository.beginObservingProxies(groupId: group.id)
    }
    
    // MARK: - Add Group
    
    func submitAddGroup() {
        addGroupError = nil
        isAddingGroup = true
        let name = newGroupName
        Task {
            let result = await repository.addGroup(name: name)
            isAddingGroup = false
            switch result {
            case .success(let group):
                newGroupName = ""
                selectGroup(group)
                AnalyticsManager.shared.log(.proxyGroupAdded)
            case .failure(let error):
                addGroupError = error.errorDescription
            }
        }
    }
    
    // MARK: - Remove Group
    
    func confirmRemoveGroup(_ group: ProxyGroup) {
        groupPendingRemoval = group
    }
    
    func performRemoveGroup() {
        guard let group = groupPendingRemoval else { return }
        groupPendingRemoval = nil
        removeGroupError = nil
        isRemovingGroup = true
        Task {
            let result = await repository.removeGroup(group)
            isRemovingGroup = false
            switch result {
            case .success:
                AnalyticsManager.shared.log(.proxyGroupRemoved)
            case .failure(let error):
                removeGroupError = error.errorDescription
            }
        }
    }
    
    // MARK: - Add Proxy (manual)
    
    func submitAddProxy() {
        guard let groupId = selectedGroupID else {
            addProxyError = ManagedProxyError.noGroupSelected.errorDescription
            return
        }
        addProxyError = nil
        isAddingProxy = true
        let host = hostText
        let port = portText
        let username = usernameText
        let password = passwordText
        Task {
            let result = await repository.addProxy(
                groupId: groupId,
                host: host,
                port: port,
                username: username,
                password: password
            )
            isAddingProxy = false
            switch result {
            case .success:
                hostText = ""
                portText = ""
                usernameText = ""
                passwordText = ""
                AnalyticsManager.shared.log(.proxyAdded)
            case .failure(let error):
                addProxyError = error.errorDescription
            }
        }
    }
    
    // MARK: - Proxy table
    
    func togglePasswordReveal(_ proxy: ManagedProxy) {
        if revealedProxyIDs.contains(proxy.id) {
            revealedProxyIDs.remove(proxy.id)
        } else {
            revealedProxyIDs.insert(proxy.id)
        }
    }
    
    func confirmDeleteProxy(_ proxy: ManagedProxy) {
        proxyPendingDeletion = proxy
    }
    
    func performDeleteProxy() {
        guard let groupId = selectedGroupID, let proxy = proxyPendingDeletion else { return }
        proxyPendingDeletion = nil
        Task {
            let result = await repository.removeProxy(groupId: groupId, proxyId: proxy.id)
            if case .failure(let error) = result {
                tableActionError = error.errorDescription
            } else {
                AnalyticsManager.shared.log(.proxyRemoved)
            }
        }
    }
    
    func confirmDeleteAllProxies() {
        guard selectedGroupID != nil, !proxiesInSelectedGroup.isEmpty else { return }
        isDeleteAllConfirmationPresented = true
    }
    
    func performDeleteAllProxies() {
        guard let groupId = selectedGroupID else { return }
        isDeleteAllConfirmationPresented = false
        Task {
            let result = await repository.removeAllProxies(groupId: groupId)
            if case .failure(let error) = result {
                tableActionError = error.errorDescription
            }
        }
    }
    
    // MARK: - Import
    
    func importFile(at url: URL) {
        guard let groupId = selectedGroupID else {
            addProxyError = ManagedProxyError.noGroupSelected.errorDescription
            return
        }
        
        let didStartAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing { url.stopAccessingSecurityScopedResource() }
        }
        
        guard let contents = try? String(contentsOf: url, encoding: .utf8) else {
            tableActionError = "Couldn't read that file. Make sure it's a plain-text .csv or .txt file."
            return
        }
        
        isImporting = true
        let existing = proxiesInSelectedGroup
        let remainingCapacity = max(0, ManageMyProxyAvailability.config.maxProxiesPerGroup - existing.count)
        
        let (parsedDrafts, parseSummary) = ProxyImportExportParser.parseImport(
            fileContents: contents,
            existingProxiesInGroup: existing
        )
        
        let toSubmit = Array(parsedDrafts.prefix(remainingCapacity))
        let truncatedByCapacity = parsedDrafts.count - toSubmit.count
        
        Task {
            let result = await repository.importProxies(groupId: groupId, drafts: toSubmit)
            isImporting = false
            switch result {
            case .success(let created):
                let summary = ProxyImportSummary(
                    addedCount: created.count,
                    skippedDuplicateCount: parseSummary.skippedDuplicateCount,
                    invalidCount: parseSummary.invalidCount + truncatedByCapacity,
                    invalidSamples: parseSummary.invalidSamples
                )
                importSummary = summary
                AnalyticsManager.shared.log(
                    .proxiesImported(
                        added: summary.addedCount,
                        skippedDuplicates: summary.skippedDuplicateCount,
                        invalid: summary.invalidCount
                    )
                )
            case .failure(let error):
                tableActionError = error.errorDescription
            }
        }
    }
    
    // MARK: - Export
    
    func prepareExport() {
        guard let groupId = selectedGroupID else { return }
        let csv = repository.exportCSV(groupId: groupId)
        guard !csv.isEmpty else {
            tableActionError = ManageMyProxyMessages.exportEmptyGroup
            return
        }
        exportDocument = ProxyExportDocument(text: csv)
        isExportPickerPresented = true
    }
    
    // MARK: - Use My Proxy
    
    func useMyProxy() {
        guard let group = selectedGroup else { return }
        useMyProxyError = nil
        AnalyticsManager.shared.log(.customProxyActivated(rotation: rotationSelection.rawValue))
        onCustomProxyActivated(group, rotationSelection)
    }
}
