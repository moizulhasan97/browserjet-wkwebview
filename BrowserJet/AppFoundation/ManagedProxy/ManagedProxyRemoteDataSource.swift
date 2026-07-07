//
//  ManagedProxyRemoteDataSource.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 07/07/2026.
//

import FirebaseFirestore
import Foundation

protocol ManagedProxyRemoteDataSource {
    @discardableResult
    func observeGroups(
        accountId: String,
        onChange: @escaping ([ProxyGroup]) -> Void
    ) -> ManagedProxyListenerHandle
    
    @discardableResult
    func observeProxies(
        accountId: String,
        groupId: String,
        onChange: @escaping ([ManagedProxy]) -> Void
    ) -> ManagedProxyListenerHandle
    
    func fetchProxiesOnce(accountId: String, groupId: String) async throws -> [ManagedProxy]

    func addGroup(accountId: String, name: String) async throws -> ProxyGroup
    func deleteGroup(accountId: String, groupId: String) async throws
    
    func addProxy(accountId: String, groupId: String, draft: ManagedProxyDraft) async throws -> ManagedProxy
    func addProxies(
        accountId: String,
        groupId: String,
        drafts: [ManagedProxyDraft]
    ) async throws -> [ManagedProxy]
    func deleteProxy(accountId: String, groupId: String, proxyId: String) async throws
    func deleteAllProxies(accountId: String, groupId: String) async throws
}

final class ManagedProxyListenerHandle {
    private let registration: ListenerRegistration
    
    init(_ registration: ListenerRegistration) {
        self.registration = registration
    }
    
    func cancel() {
        registration.remove()
    }
}

final class FirestoreManagedProxyDataSource: ManagedProxyRemoteDataSource {
    private let db = Firestore.firestore()
    
    /// `proxyAccounts/{accountId}` is a path namespace only — no document is ever written there.
    /// Groups/proxies subcollections exist under it without a parent document, which Firestore
    /// allows. See 00-Overview-and-Setup.md for why the account-level doc was removed.
    private func groupsRef(_ accountId: String) -> CollectionReference {
        db.collection("proxyAccounts").document(accountId).collection("groups")
    }

    private func proxiesRef(_ accountId: String, _ groupId: String) -> CollectionReference {
        groupsRef(accountId).document(groupId).collection("proxies")
    }

    // MARK: - Groups (listener)
    @discardableResult
    func observeGroups(
        accountId: String,
        onChange: @escaping ([ProxyGroup]) -> Void
    ) -> ManagedProxyListenerHandle {
        let registration = groupsRef(accountId)
            .order(by: "createdAt", descending: false)
            .addSnapshotListener { snapshot, error in
                if let error {
                    AppLogger.warning("ManagedProxy: groups listener error - \(error.localizedDescription)")
                    return
                }
                guard let documents = snapshot?.documents else { return }
                let groups = documents.compactMap { document in
                    ProxyGroup(id: document.documentID, data: self.normalizeTimestamps(document.data()))
                }
                onChange(groups)
            }
        return ManagedProxyListenerHandle(registration)
    }
    
    // MARK: - Proxies (listener + one-shot)
    
    @discardableResult
    func observeProxies(
        accountId: String,
        groupId: String,
        onChange: @escaping ([ManagedProxy]) -> Void
    ) -> ManagedProxyListenerHandle {
        let registration = proxiesRef(accountId, groupId)
            .order(by: "createdAt", descending: false)
            .addSnapshotListener { snapshot, error in
                if let error {
                    AppLogger.warning("ManagedProxy: proxies listener error - \(error.localizedDescription)")
                    return
                }
                guard let documents = snapshot?.documents else { return }
                let proxies = documents.compactMap { document in
                    ManagedProxy(id: document.documentID, data: self.normalizeTimestamps(document.data()))
                }
                onChange(proxies)
            }
        return ManagedProxyListenerHandle(registration)
    }
    
    func fetchProxiesOnce(accountId: String, groupId: String) async throws -> [ManagedProxy] {
        let snapshot = try await proxiesRef(accountId, groupId).getDocuments()
        return snapshot.documents.compactMap {
            ManagedProxy(id: $0.documentID, data: normalizeTimestamps($0.data()))
        }
    }
    
    // MARK: - Group mutations
    
    func addGroup(accountId: String, name: String) async throws -> ProxyGroup {
        let ref = groupsRef(accountId).document()
        let now = Date()
        let payload: [String: Any] = [
            "name": name,
            "normalizedName": ProxyGroup.normalizedName(name),
            "proxyCount": 0,
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ]
        try await ref.setData(payload)
        return ProxyGroup(
            id: ref.documentID,
            name: name,
            proxyCount: 0,
            createdAt: now,
            updatedAt: now
        )
    }

    func deleteGroup(accountId: String, groupId: String) async throws {
        let proxiesSnapshot = try await proxiesRef(accountId, groupId).getDocuments()
        
        let batch = db.batch()
        for document in proxiesSnapshot.documents {
            batch.deleteDocument(document.reference)
        }
        batch.deleteDocument(groupsRef(accountId).document(groupId))
        try await batch.commit()
    }
    
    // MARK: - Proxy mutations
    
    func addProxy(accountId: String, groupId: String, draft: ManagedProxyDraft) async throws -> ManagedProxy {
        let ref = proxiesRef(accountId, groupId).document()
        let now = Date()
        let payload: [String: Any] = [
            "host": draft.host,
            "port": draft.port,
            "username": draft.username,
            "password": draft.password,
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ]
        try await ref.setData(payload)
        try await groupsRef(accountId).document(groupId).updateData([
            "proxyCount": FieldValue.increment(Int64(1)),
            "updatedAt": FieldValue.serverTimestamp()
        ])
        return ManagedProxy(
            id: ref.documentID,
            host: draft.host,
            port: draft.port,
            username: draft.username,
            password: draft.password,
            createdAt: now,
            updatedAt: now
        )
    }
    
    func addProxies(
        accountId: String,
        groupId: String,
        drafts: [ManagedProxyDraft]
    ) async throws -> [ManagedProxy] {
        guard !drafts.isEmpty else { return [] }
        
        let collection = proxiesRef(accountId, groupId)
        let batch = db.batch()
        var created: [ManagedProxy] = []
        let now = Date()
        
        for draft in drafts {
            let ref = collection.document()
            batch.setData(
                [
                    "host": draft.host,
                    "port": draft.port,
                    "username": draft.username,
                    "password": draft.password,
                    "createdAt": FieldValue.serverTimestamp(),
                    "updatedAt": FieldValue.serverTimestamp()
                ],
                forDocument: ref
            )
            created.append(
                ManagedProxy(
                    id: ref.documentID,
                    host: draft.host,
                    port: draft.port,
                    username: draft.username,
                    password: draft.password,
                    createdAt: now,
                    updatedAt: now
                )
            )
        }
        
        batch.updateData(
            [
                "proxyCount": FieldValue.increment(Int64(drafts.count)),
                "updatedAt": FieldValue.serverTimestamp()
            ],
            forDocument: groupsRef(accountId).document(groupId)
        )
        
        try await batch.commit()
        return created
    }
    
    func deleteProxy(accountId: String, groupId: String, proxyId: String) async throws {
        let batch = db.batch()
        batch.deleteDocument(proxiesRef(accountId, groupId).document(proxyId))
        batch.updateData(
            [
                "proxyCount": FieldValue.increment(Int64(-1)),
                "updatedAt": FieldValue.serverTimestamp()
            ],
            forDocument: groupsRef(accountId).document(groupId)
        )
        try await batch.commit()
    }
    
    func deleteAllProxies(accountId: String, groupId: String) async throws {
        let snapshot = try await proxiesRef(accountId, groupId).getDocuments()
        guard !snapshot.documents.isEmpty else { return }
        
        let batch = db.batch()
        for document in snapshot.documents {
            batch.deleteDocument(document.reference)
        }
        batch.updateData(
            [
                "proxyCount": 0,
                "updatedAt": FieldValue.serverTimestamp()
            ],
            forDocument: groupsRef(accountId).document(groupId)
        )
        try await batch.commit()
    }
    
    // MARK: - Helpers
    private func normalizeTimestamps(_ data: [String: Any]) -> [String: Any] {
        var normalized = data
        for (key, value) in data {
            if let timestamp = value as? Timestamp {
                normalized[key] = timestamp.dateValue()
            }
        }
        return normalized
    }
}
