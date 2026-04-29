//
//  VPNConfiguration.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 19/02/2026.
//

struct VPNConfiguration: Identifiable, Hashable {
    let id: String
    let displayName: String
    
    let baseIP: String
    let portGenerationConfig: PortGenerationConfig
    let password: String
    
    let usernameStrategy: UsernameGenerationStrategy
    
    let ipGenerationConfig: IPGenerationConfig
    
    /// When set, built-in proxies use datatude usernames on `host:port` instead of zipped IP/port slots.
    let datatudePoolConfig: DatatudePoolConfig?
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(displayName)
        hasher.combine(baseIP)
        hasher.combine(portGenerationConfig)
        hasher.combine(password)
        hasher.combine(ipGenerationConfig)
        hasher.combine(datatudePoolConfig)
        
        switch usernameStrategy {
        case .static(let username):
            hasher.combine("static")
            hasher.combine(username)
        case .sequential(let base, let startIndex):
            hasher.combine("sequential")
            hasher.combine(base)
            hasher.combine(startIndex)
        case .custom:
            hasher.combine("custom")
        }
    }
    
    static func == (lhs: VPNConfiguration, rhs: VPNConfiguration) -> Bool {
        lhs.id == rhs.id &&
        lhs.displayName == rhs.displayName &&
        lhs.baseIP == rhs.baseIP &&
        lhs.portGenerationConfig == rhs.portGenerationConfig &&
        lhs.password == rhs.password &&
        lhs.ipGenerationConfig == rhs.ipGenerationConfig &&
        lhs.datatudePoolConfig == rhs.datatudePoolConfig &&
        lhs.usernameStrategyMatches(rhs.usernameStrategy)
    }
    
    private func usernameStrategyMatches(_ other: UsernameGenerationStrategy) -> Bool {
        switch (usernameStrategy, other) {
        case (.static(let a), .static(let b)): return a == b
        case (.sequential(let a, let ai), .sequential(let b, let bi)):
            return a == b && ai == bi
        case (.custom, .custom): return true
        default: return false
        }
    }
}

struct IPGenerationConfig: Hashable {
    // sequential IPs (142.173.65.60, 142.173.65.61, etc.)
    // different pattern (151.145.134.153, 151.145.134.154, etc.)
    let ipPattern: IPPattern
    let count: Int
}

enum IPPattern: Hashable {
    case sequential(baseIP: String, startIndex: Int)  // 142.173.65.60 -> 61, 62, 63
    case custom(ips: [String])
}

enum UsernameGenerationStrategy {
    case `static`(username: String)
    case sequential(base: String, startIndex: Int)  // Y9PQL, Y9PQL+1, etc.
    case custom(generator: (Int) -> String)  // Custom logic per VPN
}

enum PortPattern: Hashable {
    case `static`(port: UInt16)  // Same port for all proxies
    case sequential(basePort: UInt16, startIndex: Int)  // 16020, 16021, 16022...
    case custom(ports: [UInt16])  // [14843, 14844, 14845, 7672]
}

struct PortGenerationConfig: Hashable {
    let portPattern: PortPattern
    let count: Int
}
