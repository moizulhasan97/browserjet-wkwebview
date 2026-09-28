//
//  ProxyPoolTemplate.swift
//  BrowserJet
//

import Foundation

enum ProxyPoolTemplateError: Error, LocalizedError {
    case emptyField(String)
    case invalidHostCount(Int)
    case invalidPort(Int)
    case invalidSessionIDRange(min: Int, max: Int)
    case missingPlaceholder(String)

    var errorDescription: String? {
        switch self {
        case .emptyField(let name):
            return "ProxyPoolTemplate: \(name) must not be empty."
        case .invalidHostCount(let count):
            return "ProxyPoolTemplate: hostCount must be at least 1 (got \(count))."
        case .invalidPort(let port):
            return "ProxyPoolTemplate: port must be in 1...65535 (got \(port))."
        case let .invalidSessionIDRange(min, max):
            return "ProxyPoolTemplate: session id range \(min)...\(max) is invalid."
        case .missingPlaceholder(let placeholder):
            return "ProxyPoolTemplate: usernameTemplate must contain \(placeholder)."
        }
    }
}

/// Provider-agnostic definition of a built-in proxy pool, delivered by Remote Config
/// (`builtin_vpn_config` → `pools.<vpn id>`). Proxies are generated on demand; nothing is bundled in the app.
///
/// Placeholders, usable in both `hostTemplate` and `usernameTemplate`:
/// - `{hostIndex}`: 1-based gateway index in `1...hostCount`, derived from the session id.
/// - `{region}`: region slug from `regionSlugs`, falling back to `RegionType.defaultProxySlug`.
/// - `{sessionId}`: sticky-session id from `sessionIDRange`; it pins the exit IP.
///
/// Every instance is valid by construction: the throwing initializer is the only way to build one.
struct ProxyPoolTemplate: Hashable {
    enum Placeholder {
        static let hostIndex = "{hostIndex}"
        static let region = "{region}"
        static let sessionID = "{sessionId}"
    }

    let hostTemplate: String
    let hostCount: Int
    let port: UInt16
    let usernameTemplate: String
    let password: String
    let sessionIDRange: ClosedRange<Int>
    /// Optional slug overrides keyed by `RegionType.rawValue`, e.g. `["UK": "uk"]`.
    let regionSlugs: [String: String]

    init(
        hostTemplate: String,
        hostCount: Int,
        port: Int,
        usernameTemplate: String,
        password: String,
        sessionIDMin: Int,
        sessionIDMax: Int,
        regionSlugs: [String: String] = [:]
    ) throws {
        guard !hostTemplate.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ProxyPoolTemplateError.emptyField("hostTemplate")
        }
        guard !password.isEmpty else {
            throw ProxyPoolTemplateError.emptyField("password")
        }
        guard hostCount >= 1 else {
            throw ProxyPoolTemplateError.invalidHostCount(hostCount)
        }
        guard let validPort = UInt16(exactly: port), validPort > 0 else {
            throw ProxyPoolTemplateError.invalidPort(port)
        }
        guard sessionIDMin >= 0, sessionIDMin <= sessionIDMax, sessionIDMax < Int.max else {
            throw ProxyPoolTemplateError.invalidSessionIDRange(min: sessionIDMin, max: sessionIDMax)
        }
        // Without a session id every tab would share one sticky session, i.e. one exit IP.
        guard usernameTemplate.contains(Placeholder.sessionID) else {
            throw ProxyPoolTemplateError.missingPlaceholder(Placeholder.sessionID)
        }

        self.hostTemplate = hostTemplate
        self.hostCount = hostCount
        self.port = validPort
        self.usernameTemplate = usernameTemplate
        self.password = password
        self.sessionIDRange = sessionIDMin...sessionIDMax
        self.regionSlugs = regionSlugs
    }
}

// MARK: - Decoding

extension ProxyPoolTemplate: Decodable {
    private enum CodingKeys: String, CodingKey {
        case hostTemplate
        case hostCount
        case port
        case usernameTemplate
        case password
        case sessionIdMin
        case sessionIdMax
        case regionSlugs
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            hostTemplate: container.decode(String.self, forKey: .hostTemplate),
            hostCount: container.decodeIfPresent(Int.self, forKey: .hostCount) ?? 1,
            port: container.decode(Int.self, forKey: .port),
            usernameTemplate: container.decode(String.self, forKey: .usernameTemplate),
            password: container.decode(String.self, forKey: .password),
            sessionIDMin: container.decode(Int.self, forKey: .sessionIdMin),
            sessionIDMax: container.decode(Int.self, forKey: .sessionIdMax),
            regionSlugs: container.decodeIfPresent([String: String].self, forKey: .regionSlugs) ?? [:]
        )
    }
}

// MARK: - Proxy generation

extension ProxyPoolTemplate {
    func regionSlug(for region: RegionType) -> String {
        regionSlugs[region.rawValue] ?? region.defaultProxySlug
    }

    /// Builds the proxy for one sticky session. Deterministic: a session id always maps to the same gateway.
    func makeProxy(sessionID: Int, region: RegionType) -> AuthProxy {
        let values = [
            Placeholder.hostIndex: String(sessionID % hostCount + 1),
            Placeholder.region: regionSlug(for: region),
            Placeholder.sessionID: String(sessionID)
        ]
        return AuthProxy(
            host: Self.render(hostTemplate, with: values),
            port: port,
            username: Self.render(usernameTemplate, with: values),
            password: password
        )
    }

    private static func render(_ template: String, with values: [String: String]) -> String {
        values.reduce(template) { rendered, placeholder in
            rendered.replacingOccurrences(of: placeholder.key, with: placeholder.value)
        }
    }
}
