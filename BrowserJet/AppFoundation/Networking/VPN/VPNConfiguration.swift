//
//  VPNConfiguration.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 19/02/2026.
//

//enum VPNConfigurationLayout: Hashable {
//    /// IP list × port list × username strategy (e.g. VPN1 metadata / non-datatude pools).
//    case multiSlotZip(
//        //baseIP: String,
//        password: String,
//        portGenerationConfig: PortGenerationConfig,
//        ipGenerationConfig: IPGenerationConfig,
//        usernameStrategy: UsernameGenerationStrategy
//    )
//    /// single host:port + password; usernames from counter + region at runtime.
//    case datatude(DatatudePoolConfig)
//    
//    func hash(into hasher: inout Hasher) {
//        switch self {
//        case .multiSlotZip(let password, let portGen, let ipGen, let usernameStrategy):
//            hasher.combine("multi")
//            //hasher.combine(baseIP)
//            hasher.combine(password)
//            hasher.combine(portGen)
//            hasher.combine(ipGen)
//            Self.hashUsernameStrategy(usernameStrategy, into: &hasher)
//        case .datatude(let pool):
//            hasher.combine("datatude")
//            hasher.combine(pool)
//        }
//    }
//    
//    static func == (lhs: VPNConfigurationLayout, rhs: VPNConfigurationLayout) -> Bool {
//        switch (lhs, rhs) {
//        case (
//            .multiSlotZip(let p1, let pp1, let i1, let u1),
//            .multiSlotZip(let p2, let pp2, let i2, let u2)
//        ):
//            return p1 == p2 && pp1 == pp2 && i1 == i2
//            && usernameStrategyMatches(u1, u2)
//        case (.datatude(let a), .datatude(let b)):
//            return a == b
//        default:
//            return false
//        }
//    }
//    
//    private static func usernameStrategyMatches(
//        _ a: UsernameGenerationStrategy,
//        _ b: UsernameGenerationStrategy
//    ) -> Bool {
//        switch (a, b) {
//        case (.static(let x), .static(let y)): return x == y
//        case (.sequential(let x, let xi), .sequential(let y, let yi)):
//            return x == y && xi == yi
//        case (.custom, .custom): return true
//        default: return false
//        }
//    }
//    
//    private static func hashUsernameStrategy(
//        _ strategy: UsernameGenerationStrategy,
//        into hasher: inout Hasher
//    ) {
//        switch strategy {
//        case .static(let username):
//            hasher.combine("static")
//            hasher.combine(username)
//        case .sequential(let base, let startIndex):
//            hasher.combine("sequential")
//            hasher.combine(base)
//            hasher.combine(startIndex)
//        case .custom:
//            hasher.combine("custom")
//        }
//    }
//}

enum VPNConfigurationLayout: Hashable {
    /// Proxies come from a remote API e.g., VPN1
    case remoteManaged
    
    /// Local: zip IP list × port list × username strategy.
    case multiSlotZip(
        password: String,
        portGenerationConfig: PortGenerationConfig,
        ipGenerationConfig: IPGenerationConfig,
        usernameStrategy: UsernameGenerationStrategy
    )
    
    /// Local: single host:port + password; usernames from counter + region at runtime.
    case datatude(DatatudePoolConfig)
    
    func hash(into hasher: inout Hasher) {
        switch self {
        case .remoteManaged:
            hasher.combine("remoteManaged")
        case .multiSlotZip(let password, let portGen, let ipGen, let usernameStrategy):
            hasher.combine("multi")
            hasher.combine(password)
            hasher.combine(portGen)
            hasher.combine(ipGen)
            Self.hashUsernameStrategy(usernameStrategy, into: &hasher)
        case .datatude(let pool):
            hasher.combine("datatude")
            hasher.combine(pool)
        }
    }
    
    static func == (lhs: VPNConfigurationLayout, rhs: VPNConfigurationLayout) -> Bool {
        switch (lhs, rhs) {
        case (.remoteManaged, .remoteManaged):
            return true
        case (
            .multiSlotZip(let p1, let pp1, let i1, let u1),
            .multiSlotZip(let p2, let pp2, let i2, let u2)
        ):
            return p1 == p2 && pp1 == pp2 && i1 == i2
            && Self.usernameStrategyMatches(u1, u2)
        case (.datatude(let a), .datatude(let b)):
            return a == b
        default:
            return false
        }
    }
    
    private static func usernameStrategyMatches(
        _ a: UsernameGenerationStrategy,
        _ b: UsernameGenerationStrategy
    ) -> Bool {
        switch (a, b) {
        case (.static(let x), .static(let y)): return x == y
        case (.sequential(let x, let xi), .sequential(let y, let yi)):
            return x == y && xi == yi
        case (.custom, .custom): return true
        default: return false
        }
    }
    
    private static func hashUsernameStrategy(
        _ strategy: UsernameGenerationStrategy,
        into hasher: inout Hasher
    ) {
        switch strategy {
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
}

struct VPNConfiguration: Identifiable, Hashable {
    let id: String
    let displayName: String
    let layout: VPNConfigurationLayout
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(displayName)
        hasher.combine(layout)
    }
    
    static func == (lhs: VPNConfiguration, rhs: VPNConfiguration) -> Bool {
        lhs.id == rhs.id && lhs.displayName == rhs.displayName && lhs.layout == rhs.layout
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
