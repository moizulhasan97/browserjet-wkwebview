//
//  PlansConfig.swift
//  BrowserJet
//

import Foundation

/// Remote Config `plans_config`: which plan each backend tier code maps to, and what each plan unlocks.
///
/// Why: package rules (tab limits, VPN access, Premium Proxy, trial allowance) are business decisions that
/// change more often than releases. Keeping them here lets them be changed from Firebase, while the in-app
/// `.default` keeps the app safe (never more than Basic for an unknown user) when Remote Config is unavailable.
struct PlansConfig: Decodable {
    static let supportedSchemaVersion = 1

    let schemaVersion: Int
    /// Plan for paid users whose tier code is unknown, or maps to a plan that isn't defined.
    let fallbackPlan: PlanID
    /// Plan applied to every trial user. The backend tier code is ignored for trials; the `5tab` lock is
    /// still handled by the licence's `trialExpired` flag and is intentionally not part of this config.
    let trialPlan: PlanID
    /// Normalised backend tier code (trimmed, lower-cased; `""` is the empty code) → plan.
    let tierCodeMap: [String: PlanID]
    let plans: [PlanID: PlanDefinition]

    var isSupported: Bool {
        schemaVersion <= Self.supportedSchemaVersion
    }

    /// A config whose fallback or trial plan isn't defined can't be resolved safely, so it is rejected as a
    /// whole (the caller falls back to `.default`) rather than half-applied.
    var isValid: Bool {
        plans[fallbackPlan] != nil && plans[trialPlan] != nil
    }

    init(
        schemaVersion: Int = 1,
        fallbackPlan: PlanID,
        trialPlan: PlanID,
        tierCodeMap: [String: PlanID],
        plans: [PlanID: PlanDefinition]
    ) {
        self.schemaVersion = schemaVersion
        self.fallbackPlan = fallbackPlan
        self.trialPlan = trialPlan
        self.tierCodeMap = Self.normalizedTierCodeMap(tierCodeMap)
        self.plans = plans
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 1
        fallbackPlan = try container.decodeIfPresent(PlanID.self, forKey: .fallbackPlan) ?? .basic
        trialPlan = try container.decodeIfPresent(PlanID.self, forKey: .trialPlan) ?? .trial
        let rawTierCodeMap = try container.decodeIfPresent([String: PlanID].self, forKey: .tierCodeMap) ?? [:]
        tierCodeMap = Self.normalizedTierCodeMap(rawTierCodeMap)
        // Plans are required: without them there is nothing to resolve, so decoding fails and the
        // caller uses the in-app default instead of guessing.
        let rawPlans = try container.decode([String: PlanDefinition].self, forKey: .plans)
        plans = Dictionary(rawPlans.map { (PlanID(rawValue: $0.key), $0.value) }) { first, _ in first }
    }

    /// Tier codes are compared trimmed and lower-cased, matching how `VerifyKeyResponse` treats them.
    static func normalizedTierCode(_ raw: String) -> String {
        raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private static func normalizedTierCodeMap(_ map: [String: PlanID]) -> [String: PlanID] {
        Dictionary(map.map { (normalizedTierCode($0.key), $0.value) }) { first, _ in first }
    }

    private enum CodingKeys: String, CodingKey {
        case schemaVersion, fallbackPlan, trialPlan, tierCodeMap, plans
    }
}

/// One plan's rules as delivered by Remote Config.
struct PlanDefinition: Decodable {
    let displayName: String
    let maxTabs: Int
    /// `VPNType` raw values (e.g. `"vpn1"`). Unknown ids are ignored, so Remote Config can reference a VPN
    /// tier before every build in the field supports it.
    let vpns: [String]
    let premiumProxy: Bool

    init(displayName: String, maxTabs: Int, vpns: [String], premiumProxy: Bool) {
        self.displayName = displayName
        self.maxTabs = maxTabs
        self.vpns = vpns
        self.premiumProxy = premiumProxy
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        displayName = try container.decodeIfPresent(String.self, forKey: .displayName) ?? ""
        // Required: there is no safe guess for a tab limit.
        maxTabs = try container.decode(Int.self, forKey: .maxTabs)
        // Omitted access fields default to "not granted" (fail closed).
        vpns = try container.decodeIfPresent([String].self, forKey: .vpns) ?? []
        premiumProxy = try container.decodeIfPresent(Bool.self, forKey: .premiumProxy) ?? false
    }

    private enum CodingKeys: String, CodingKey {
        case displayName, maxTabs, vpns, premiumProxy
    }
}

extension PlansConfig {
    /// In-app rules used when Remote Config has no value, is unreachable, or fails to decode/validate.
    /// Mirrors the package rules (Basic: 10 tabs, no VPN · Pro: 30 tabs + VPN1 · Trial: 5 tabs, no VPN) so a
    /// network or config failure never grants more than a user paid for.
    ///
    /// Tier codes: `lite` → Basic and the empty code → Pro, as the backend sends them today. Any other paid
    /// code resolves to `fallbackPlan` (Basic).
    static let `default` = PlansConfig(
        schemaVersion: 1,
        fallbackPlan: .basic,
        trialPlan: .trial,
        tierCodeMap: [
            "lite": .basic,
            "": .pro
        ],
        plans: [
            .basic: PlanDefinition(
                displayName: "Captain - Lite",
                maxTabs: 10,
                vpns: [],
                premiumProxy: true
            ),
            .pro: PlanDefinition(
                displayName: "Captain - Pro",
                maxTabs: 30,
                vpns: [VPNType.vpn1.rawValue],
                premiumProxy: true
            ),
            .trial: PlanDefinition(
                displayName: "Captain - Lite",
                maxTabs: 5,
                vpns: [],
                premiumProxy: false
            )
        ]
    )
}
