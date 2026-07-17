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
    // MARK: - Group selection

    @Published var selectedGroupID: String?
    @Published var isAddGroupPopoverPresented: Bool = false

    /// Rotation is a per-session choice, not a saved group property — it always starts at
    /// `.linear` when this view model is created (i.e. every time the window is opened) and is
    /// only applied to the launcher when "Use My Proxy" is tapped.
    @Published var rotationSelection: ProxyRotationType = .linear

    // MARK: - Add Group

    @Published var newGroupName: String = ""
    @Published var isAddingGroup: Bool = false

    // MARK: - Remove Group

    @Published var groupPendingRemoval: ProxyGroup?
    @Published var isRemovingGroup: Bool = false

    // MARK: - Add Proxy (manual)

    @Published var hostText: String = ""
    @Published var portText: String = ""
    @Published var usernameText: String = ""
    @Published var passwordText: String = ""
    @Published var isAddingProxy: Bool = false
    /// Bumped after a successful add so the view can re-focus the Host field, letting a user
    /// add several proxies in a row without reaching for the mouse.
    @Published var refocusHostFieldToken: Int = 0

    // MARK: - Proxy table

    @Published var searchText: String = ""
    @Published var revealedProxyIDs: Set<String> = []
    @Published var proxyPendingDeletion: ManagedProxy?
    @Published var isDeleteAllConfirmationPresented: Bool = false

    // MARK: - Import / Export

    @Published var isImportPickerPresented: Bool = false
    @Published var isExportPickerPresented: Bool = false
    @Published var isImporting: Bool = false
    @Published var exportDocument: ProxyExportDocument?

    // MARK: - Feedback

    /// Single source of truth for user-facing feedback — both success and error. Field-level
    /// problems (empty host, invalid port) are surfaced inline via `BrowserJetTextField`'s own
    /// validation instead of here.
    @Published var toast: ToastMessage?

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

    var filteredProxiesInSelectedGroup: [ManagedProxy] {
        let all = proxiesInSelectedGroup
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return all }
        return all.filter {
            $0.host.localizedCaseInsensitiveContains(query)
                || $0.username.localizedCaseInsensitiveContains(query)
                || String($0.port).contains(query)
        }
    }

    var availableRotationMethods: [ProxyRotationType] {
        ManageMyProxyAvailability.availableRotationMethods
    }

    var canUseMyProxy: Bool {
        !repository.isLoadingGroups
            && selectedGroup != nil
            && !proxiesInSelectedGroup.isEmpty
    }

    var canSubmitAddProxy: Bool {
        guard !isAddingProxy, selectedGroup != nil else { return false }
        let trimmedHost = hostText.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedUsername = usernameText.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = passwordText.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPort = portText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedHost.isEmpty, !trimmedUsername.isEmpty, !trimmedPassword.isEmpty else { return false }
        guard let port = Int(trimmedPort) else { return false }
        return (1...65_535).contains(port)
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
        searchText = ""
        repository.beginObservingProxies(groupId: group.id)
    }

    // MARK: - Rotation

    func cycleRotation() {
        let methods = availableRotationMethods
        guard methods.count > 1, let currentIndex = methods.firstIndex(of: rotationSelection) else { return }
        let nextIndex = methods.index(after: currentIndex)
        rotationSelection = nextIndex == methods.endIndex ? methods[methods.startIndex] : methods[nextIndex]
    }

    // MARK: - Add Group

    func submitAddGroup() {
        isAddingGroup = true
        let name = newGroupName
        Task {
            let result = await repository.addGroup(name: name)
            isAddingGroup = false
            switch result {
            case .success(let group):
                newGroupName = ""
                isAddGroupPopoverPresented = false
                selectGroup(group)
                AnalyticsManager.shared.log(.proxyGroupAdded)
                toast = ToastMessage(text: "Group \"\(group.name)\" created.")
            case .failure(let error):
                toast = ToastMessage(text: error.errorDescription ?? "Couldn't create group.", style: .error)
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
        isRemovingGroup = true
        Task {
            let result = await repository.removeGroup(group)
            isRemovingGroup = false
            switch result {
            case .success:
                AnalyticsManager.shared.log(.proxyGroupRemoved)
                toast = ToastMessage(text: "Group \"\(group.name)\" removed.")
            case .failure(let error):
                toast = ToastMessage(text: error.errorDescription ?? "Couldn't remove group.", style: .error)
            }
        }
    }

    // MARK: - Add Proxy (manual)

    func submitAddProxy() {
        guard let groupId = selectedGroupID else { return }
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
                toast = ToastMessage(text: "Proxy added.")
                refocusHostFieldToken += 1
            case .failure(let error):
                toast = ToastMessage(text: error.errorDescription ?? "Couldn't add proxy.", style: .error)
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
            switch result {
            case .success:
                AnalyticsManager.shared.log(.proxyRemoved)
                toast = ToastMessage(text: "Proxy deleted.")
            case .failure(let error):
                toast = ToastMessage(text: error.errorDescription ?? "Couldn't delete proxy.", style: .error)
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
            switch result {
            case .success:
                toast = ToastMessage(text: "All proxies removed.")
            case .failure(let error):
                toast = ToastMessage(text: error.errorDescription ?? "Couldn't delete proxies.", style: .error)
            }
        }
    }

    // MARK: - Import

    func importFile(at url: URL) {
        guard let groupId = selectedGroupID else { return }

        let didStartAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing { url.stopAccessingSecurityScopedResource() }
        }

        guard let contents = try? String(contentsOf: url, encoding: .utf8) else {
            toast = ToastMessage(
                text: "Couldn't read that file. Make sure it's a plain-text .csv or .txt file.",
                style: .error
            )
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
                AnalyticsManager.shared.log(
                    .proxiesImported(
                        added: summary.addedCount,
                        skippedDuplicates: summary.skippedDuplicateCount,
                        invalid: summary.invalidCount
                    )
                )
                toast = ToastMessage(text: summary.summaryMessage)
            case .failure(let error):
                toast = ToastMessage(text: error.errorDescription ?? "Import failed.", style: .error)
            }
        }
    }

    // MARK: - Export

    func prepareExport() {
        guard let groupId = selectedGroupID else { return }
        let csv = repository.exportCSV(groupId: groupId)
        guard !csv.isEmpty else {
            toast = ToastMessage(text: "This group has no proxies to export.", style: .error)
            return
        }
        exportDocument = ProxyExportDocument(text: csv)
        isExportPickerPresented = true
    }

    func handleExportResult(_ result: Result<URL, Error>) {
        switch result {
        case .success:
            toast = ToastMessage(text: "Export complete.")
        case .failure(let error):
            toast = ToastMessage(text: error.localizedDescription, style: .error)
        }
    }

    // MARK: - Use My Proxy

    func useMyProxy() {
        guard let group = selectedGroup else { return }
        AnalyticsManager.shared.log(.customProxyActivated(rotation: rotationSelection.rawValue))
        onCustomProxyActivated(group, rotationSelection)
    }
}
