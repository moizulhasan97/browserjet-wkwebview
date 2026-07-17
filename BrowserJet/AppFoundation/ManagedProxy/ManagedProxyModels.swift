//
//  ManagedProxyModels.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 07/07/2026.
//

import Foundation

// MARK: - Group
struct ProxyGroup: Identifiable, Hashable {
    let id: String
    let name: String
    let proxyCount: Int
    let createdAt: Date
    let updatedAt: Date

    init?(
        id: String,
        data: [String: Any]
    ) {
        guard let name = data["name"] as? String else { return nil }
        self.id = id
        self.name = name
        self.proxyCount = (data["proxyCount"] as? Int) ?? 0
        self.createdAt = (data["createdAt"] as? Date) ?? Date()
        self.updatedAt = (data["updatedAt"] as? Date) ?? self.createdAt
    }

    init(
        id: String,
        name: String,
        proxyCount: Int,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.name = name
        self.proxyCount = proxyCount
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    static func normalizedName(_ raw: String) -> String {
        raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}

// MARK: - Proxy
struct ManagedProxy: Identifiable, Hashable {
    let id: String
    let host: String
    let port: Int
    let username: String
    let password: String
    let createdAt: Date
    let updatedAt: Date
    
    init?(id: String, data: [String: Any]) {
        guard
            let host = data["host"] as? String,
            let port = data["port"] as? Int,
            let username = data["username"] as? String,
            let password = data["password"] as? String
        else { return nil }
        
        self.id = id
        self.host = host
        self.port = port
        self.username = username
        self.password = password
        self.createdAt = (data["createdAt"] as? Date) ?? Date()
        self.updatedAt = (data["updatedAt"] as? Date) ?? self.createdAt
    }
    
    init(
        id: String,
        host: String,
        port: Int,
        username: String,
        password: String,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.host = host
        self.port = port
        self.username = username
        self.password = password
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    var display: String { "\(host):\(port)" }
    
    func asAuthProxy() -> AuthProxy {
        AuthProxy(
            host: host,
            port: UInt16(clamping: port),
            username: username,
            password: password
        )
    }
}

struct ManagedProxyDraft: Hashable {
    let host: String
    let port: Int
    let username: String
    let password: String
    var duplicateKey: String {
        "\(host):\(port):\(username):\(password)"
    }
}

// MARK: - Import summary

struct ProxyImportSummary: Hashable {
    let addedCount: Int
    let skippedDuplicateCount: Int
    let invalidCount: Int
    let invalidSamples: [String]
    
    var totalLines: Int { addedCount + skippedDuplicateCount + invalidCount }
}
