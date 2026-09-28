//
//  TemplatedAuthProxyProvider.swift
//  BrowserJet
//

import Foundation

/// Generates proxies on demand from a `ProxyPoolTemplate`.
///
/// - Every request gets a random sticky-session id, so users and launches spread across the whole session
///   range instead of all starting on the same exit IPs.
/// - Ids are never re-issued by the same provider (one browser window), so "new IP" never returns to an
///   earlier session.
/// - Memory grows with the proxies handed out, not with the size of the session range.
final class TemplatedAuthProxyProvider: AuthProxyProviding {
    typealias SessionIDPicker = (ClosedRange<Int>) -> Int

    /// Random draws before falling back to a linear probe; only reached when the range is nearly used up.
    private static let maxRandomAttempts = 16

    private let template: ProxyPoolTemplate
    private let region: RegionType
    private let pickSessionID: SessionIDPicker
    private var issuedSessionIDs: Set<Int> = []

    init(
        template: ProxyPoolTemplate,
        region: RegionType,
        pickSessionID: @escaping SessionIDPicker = { Int.random(in: $0) }
    ) {
        self.template = template
        self.region = region
        self.pickSessionID = pickSessionID
    }

    func nextProxy() -> AuthProxy? {
        guard let sessionID = nextUnusedSessionID() else {
            AppLogger.warning(
                "TemplatedAuthProxyProvider: session range exhausted after \(issuedSessionIDs.count) proxies"
            )
            return nil
        }
        issuedSessionIDs.insert(sessionID)
        return template.makeProxy(sessionID: sessionID, region: region)
    }

    private func nextUnusedSessionID() -> Int? {
        let range = template.sessionIDRange
        guard issuedSessionIDs.count < range.count else { return nil }

        for _ in 0..<Self.maxRandomAttempts {
            let candidate = pickSessionID(range)
            if range.contains(candidate), !issuedSessionIDs.contains(candidate) {
                return candidate
            }
        }

        // Nearly used-up range: walk forward (wrapping) from a random point to the next free id.
        var probe = Swift.min(Swift.max(pickSessionID(range), range.lowerBound), range.upperBound)
        while issuedSessionIDs.contains(probe) {
            probe = probe == range.upperBound ? range.lowerBound : probe + 1
        }
        return probe
    }
}
