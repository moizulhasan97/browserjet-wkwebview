//
//  ManagedProxyRepository.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 07/07/2026.
//

import Combine
import Foundation

@MainActor
final class ManagedProxyRepository: ObservableObject {
    static let shared = ManagedProxyRepository()
    
    @Published private(set) var groups: [ProxyGroup] = []
    @Published private(set) var proxiesByGroupID: [String: [ManagedProxy]] = [:]
    @Published private(set) var isLoadingGroups: Bool = false
    @Published private(set) var lastError: ManagedProxyError?
    
    private let dataSource: ManagedProxyRemoteDataSource
    private let accountIdentifier: ManagedProxyAccountIdentifying
    
    private var groupsListener: ManagedProxyListenerHandle?
    private var proxiesListeners: [String: ManagedProxyListenerHandle] = [:]
    
    init(
        dataSource: ManagedProxyRemoteDataSource = FirestoreManagedProxyDataSource(),
        accountIdentifier: ManagedProxyAccountIdentifying = LicenseKeyManagedProxyAccountIdentifier()
    ) {
        self.dataSource = dataSource
        self.accountIdentifier = accountIdentifier
    }
    
    var currentAccountId: String? { accountIdentifier.currentAccountId() }
    
    func proxies(inGroupID groupID: String) -> [ManagedProxy] {
        proxiesByGroupID[groupID] ?? []
    }
    
    // MARK: - Lifecycle
    func startManaging() {
        guard ManageMyProxyAvailability.isFeatureEnabled, let accountId = currentAccountId else { return }
        guard groupsListener == nil else { return }
        
        isLoadingGroups = true
        groupsListener = dataSource.observeGroups(accountId: accountId) { [weak self] groups in
            Task { @MainActor in
                self?.groups = groups
                self?.isLoadingGroups = false
            }
        }
    }
    
    func stopManaging() {
        groupsListener?.cancel()
        groupsListener = nil
        proxiesListeners.values.forEach { $0.cancel() }
        proxiesListeners.removeAll()
    }
    
    func beginObservingProxies(groupId: String) {
        guard let accountId = currentAccountId, proxiesListeners[groupId] == nil else { return }
        proxiesListeners[groupId] = dataSource.observeProxies(accountId: accountId, groupId: groupId) { [weak self] proxies in
            Task { @MainActor in
                self?.proxiesByGroupID[groupId] = proxies
            }
        }
    }
    
    func stopObservingProxies(groupId: String) {
        proxiesListeners[groupId]?.cancel()
        proxiesListeners.removeValue(forKey: groupId)
    }
    
    func fetchAuthProxySnapshot(groupId: String) async -> [AuthProxy] {
        guard let accountId = currentAccountId else { return [] }
        do {
            let proxies = try await dataSource.fetchProxiesOnce(accountId: accountId, groupId: groupId)
            return proxies.map { $0.asAuthProxy() }
        } catch {
            AppLogger.warning("ManagedProxyRepository: proxy snapshot fetch failed - \(error.localizedDescription)")
            return []
        }
    }
    
    // MARK: - Groups
    
    @discardableResult
    func addGroup(name: String) async -> Result<ProxyGroup, ManagedProxyError> {
        guard let accountId = currentAccountId else { return .failure(.accountNotResolved) }
        
        let existingNormalized = Set(groups.map { ProxyGroup.normalizedName($0.name) })
        switch ManagedProxyValidator.validateGroupName(name, existingNormalizedNames: existingNormalized) {
        case .failure(let error):
            return .failure(error)
        case .success(let trimmedName):
            guard groups.count < ManageMyProxyAvailability.config.maxGroupsPerAccount else {
                return .failure(.groupLimitReached(ManageMyProxyAvailability.config.maxGroupsPerAccount))
            }
            do {
                let group = try await dataSource.addGroup(accountId: accountId, name: trimmedName)
                return .success(group)
            } catch {
                return .failure(.remote(error.localizedDescription))
            }
        }
    }

    @discardableResult
    func removeGroup(_ group: ProxyGroup) async -> Result<Void, ManagedProxyError> {
        guard let accountId = currentAccountId else { return .failure(.accountNotResolved) }
        do {
            try await dataSource.deleteGroup(accountId: accountId, groupId: group.id)
            stopObservingProxies(groupId: group.id)
            proxiesByGroupID.removeValue(forKey: group.id)
            return .success(())
        } catch {
            return .failure(.remote(error.localizedDescription))
        }
    }
    
    // MARK: - Proxies
    
    @discardableResult
    func addProxy(
        groupId: String,
        host: String,
        port: String,
        username: String,
        password: String
    ) async -> Result<ManagedProxy, ManagedProxyError> {
        guard let accountId = currentAccountId else { return .failure(.accountNotResolved) }
        
        switch ManagedProxyValidator.validateProxyFields(host: host, port: port, username: username, password: password) {
        case .failure(let error):
            return .failure(error)
        case .success(let draft):
            let existing = proxies(inGroupID: groupId)
            guard !ManagedProxyValidator.isDuplicate(draft, in: existing) else {
                return .failure(.duplicateProxy)
            }
            guard existing.count < ManageMyProxyAvailability.config.maxProxiesPerGroup else {
                return .failure(.proxyLimitReached(ManageMyProxyAvailability.config.maxProxiesPerGroup))
            }
            do {
                let proxy = try await dataSource.addProxy(accountId: accountId, groupId: groupId, draft: draft)
                return .success(proxy)
            } catch {
                return .failure(.remote(error.localizedDescription))
            }
        }
    }
    
    @discardableResult
    func removeProxy(groupId: String, proxyId: String) async -> Result<Void, ManagedProxyError> {
        guard let accountId = currentAccountId else { return .failure(.accountNotResolved) }
        do {
            try await dataSource.deleteProxy(accountId: accountId, groupId: groupId, proxyId: proxyId)
            return .success(())
        } catch {
            return .failure(.remote(error.localizedDescription))
        }
    }
    
    @discardableResult
    func removeAllProxies(groupId: String) async -> Result<Void, ManagedProxyError> {
        guard let accountId = currentAccountId else { return .failure(.accountNotResolved) }
        do {
            try await dataSource.deleteAllProxies(accountId: accountId, groupId: groupId)
            return .success(())
        } catch {
            return .failure(.remote(error.localizedDescription))
        }
    }
    
    func importProxies(groupId: String, drafts: [ManagedProxyDraft]) async -> Result<[ManagedProxy], ManagedProxyError> {
        guard let accountId = currentAccountId else { return .failure(.accountNotResolved) }
        guard !drafts.isEmpty else { return .success([]) }
        do {
            let created = try await dataSource.addProxies(accountId: accountId, groupId: groupId, drafts: drafts)
            return .success(created)
        } catch {
            return .failure(.remote(error.localizedDescription))
        }
    }
    
    func exportCSV(groupId: String) -> String {
        ProxyImportExportParser.exportCSV(proxies(inGroupID: groupId))
    }
}
