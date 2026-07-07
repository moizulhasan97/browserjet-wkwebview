//
//  ManagedProxyError.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 07/07/2026.
//

import Foundation

enum ManagedProxyError: LocalizedError, Equatable {
    case accountNotResolved
    case emptyGroupName
    case duplicateGroupName(String)
    case groupNotFound
    case noGroupSelected
    case groupLimitReached(Int)
    case proxyLimitReached(Int)
    case invalidHost
    case invalidPort
    case missingUsername
    case missingPassword
    case duplicateProxy
    case remote(String)
    
    var errorDescription: String? {
        switch self {
        case .accountNotResolved:
            return "We couldn't identify your account. Please make sure BrowserJet is activated."
        case .emptyGroupName:
            return "Group name can't be empty."
        case .duplicateGroupName(let name):
            return "A group named \"\(name)\" already exists."
        case .groupNotFound:
            return "That group no longer exists."
        case .noGroupSelected:
            return "Select a group first."
        case .groupLimitReached(let max):
            return "You can create up to \(max) groups."
        case .proxyLimitReached(let max):
            return "Each group can hold up to \(max) proxies."
        case .invalidHost:
            return "Enter a valid IP address or host."
        case .invalidPort:
            return "Port must be a number between 1 and 65535."
        case .missingUsername:
            return "Username is required."
        case .missingPassword:
            return "Password is required."
        case .duplicateProxy:
            return "This proxy already exists in the selected group."
        case .remote(let message):
            return message
        }
    }
}
