//
//  AuthProxy.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 16/02/2026.
//


import Foundation

struct AuthProxy: Hashable, Identifiable {
    let id = UUID()

    let host: String
    let port: UInt16
    let username: String
    let password: String

    var display: String {
        "\(host):\(port)"
    }
}

// MARK: - Parsing

extension AuthProxy {
    
    static func parse(_ raw: String) -> AuthProxy {
            // format: ip:port:user:pass
            let parts = raw.split(separator: ":").map(String.init)
            precondition(parts.count == 4, "Invalid proxy format. Expected ip:port:user:pass")

            return AuthProxy(
                host: parts[0],
                port: UInt16(parts[1]) ?? 0,
                username: parts[2],
                password: parts[3]
            )
        }
}
