//
//  VPNConfiguration.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 19/02/2026.
//

enum VPNConfigurationLayout: Hashable {
    /// Pool definition delivered by Remote Config (`builtin_vpn_config` → `pools.<vpn id>`);
    /// proxies are generated on demand per browser window.
    case remoteConfigPool

    /// Local: zip IP list × port list × username strategy.
    case multiSlotZip(
        password: String,
        portGenerationConfig: PortGenerationConfig,
        ipGenerationConfig: IPGenerationConfig,
        usernameStrategy: UsernameGenerationStrategy
    )

    func hash(into hasher: inout Hasher) {
        switch self {
        case .remoteConfigPool:
            hasher.combine("remoteConfigPool")
        case let .multiSlotZip(password, portGen, ipGen, usernameStrategy):
            hasher.combine("multi")
            hasher.combine(password)
            hasher.combine(portGen)
            hasher.combine(ipGen)
            Self.hashUsernameStrategy(usernameStrategy, into: &hasher)
        }
    }

    static func == (lhs: VPNConfigurationLayout, rhs: VPNConfigurationLayout) -> Bool {
        switch (lhs, rhs) {
        case (.remoteConfigPool, .remoteConfigPool):
            return true
        case let (
            .multiSlotZip(lhsPassword, lhsPortConfig, lhsIPConfig, lhsUsernameStrategy),
            .multiSlotZip(rhsPassword, rhsPortConfig, rhsIPConfig, rhsUsernameStrategy)
        ):
            return lhsPassword == rhsPassword
                && lhsPortConfig == rhsPortConfig
                && lhsIPConfig == rhsIPConfig
                && Self.usernameStrategyMatches(lhsUsernameStrategy, rhsUsernameStrategy)
        default:
            return false
        }
    }

    private static func usernameStrategyMatches(
        _ lhs: UsernameGenerationStrategy,
        _ rhs: UsernameGenerationStrategy
    ) -> Bool {
        switch (lhs, rhs) {
        case let (.static(lhsUsername), .static(rhsUsername)):
            return lhsUsername == rhsUsername
        case let (.sequential(lhsBase, lhsStartIndex), .sequential(rhsBase, rhsStartIndex)):
            return lhsBase == rhsBase && lhsStartIndex == rhsStartIndex
        case (.custom, .custom): return true
        default: return false
        }
    }

    private static func hashUsernameStrategy(
        _ strategy: UsernameGenerationStrategy,
        into hasher: inout Hasher
    ) {
        switch strategy {
        case let .static(username):
            hasher.combine("static")
            hasher.combine(username)
        case let .sequential(base, startIndex):
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
