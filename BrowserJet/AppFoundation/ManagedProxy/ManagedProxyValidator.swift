//
//  ManagedProxyValidator.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 07/07/2026.
//

import Foundation

enum ManagedProxyValidator {
    // MARK: - Group name
    static func validateGroupName(
        _ raw: String,
        existingNormalizedNames: Set<String>
    ) -> Result<String, ManagedProxyError> {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .failure(.emptyGroupName) }
        
        let normalized = ProxyGroup.normalizedName(trimmed)
        guard !existingNormalizedNames.contains(normalized) else {
            return .failure(.duplicateGroupName(trimmed))
        }
        
        return .success(trimmed)
    }
    
    // MARK: - Proxy fields
    static func validateProxyFields(
        host: String,
        port: String,
        username: String,
        password: String
    ) -> Result<ManagedProxyDraft, ManagedProxyError> {
        let trimmedHost = host.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPort = port.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedHost.isEmpty else { return .failure(.invalidHost) }
        
        guard let portValue = Int(trimmedPort), portValue >= 1, portValue <= 65_535 else {
            return .failure(.invalidPort)
        }
        
        guard !trimmedUsername.isEmpty else { return .failure(.missingUsername) }
        guard !trimmedPassword.isEmpty else { return .failure(.missingPassword) }
        
        return .success(
            ManagedProxyDraft(
                host: trimmedHost,
                port: portValue,
                username: trimmedUsername,
                password: trimmedPassword
            )
        )
    }
    
    // MARK: - Duplicates
    static func isDuplicate(_ candidate: ManagedProxyDraft, in existing: [ManagedProxy]) -> Bool {
        let existingKeys = Set(existing.map { "\($0.host):\($0.port):\($0.username):\($0.password)" })
        return existingKeys.contains(candidate.duplicateKey)
    }
}
