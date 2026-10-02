//
//  PlanResolver.swift
//  BrowserJet
//

import Foundation

/// Pure mapping from licence facts to a plan and its entitlements.
///
/// Why a separate, singleton-free type: the launcher, the About screen and Remote Config targeting must all
/// resolve a user's plan identically, and the rules must be unit-testable without Firebase or UserDefaults.
enum PlanResolver {
    static func planID(userKind: UserKind?, tierCode: String, config: PlansConfig) -> PlanID {
        switch userKind {
        case .trial:
            // Trials are identified by user kind, not by tier code.
            return definedPlan(config.trialPlan, in: config)
        case .paid:
            let mapped = config.tierCodeMap[PlansConfig.normalizedTierCode(tierCode)]
            return definedPlan(mapped ?? config.fallbackPlan, in: config)
        case nil:
            // No persisted licence yet (the launcher is never shown in this state): most conservative plan.
            return config.fallbackPlan
        }
    }

    static func entitlements(for planID: PlanID, in config: PlansConfig) -> PlanEntitlements {
        guard let definition = config.plans[planID] else {
            return .restricted(planID: planID)
        }
        let displayName = definition.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        return PlanEntitlements(
            planID: planID,
            displayName: displayName.isEmpty ? planID.rawValue.capitalized : displayName,
            maxTabs: definition.maxTabs,
            allowedVPNs: Set(definition.vpns.compactMap(Self.vpnType(from:))),
            isPremiumProxyAllowed: definition.premiumProxy
        )
    }

    static func entitlements(userKind: UserKind?, tierCode: String, config: PlansConfig) -> PlanEntitlements {
        entitlements(for: planID(userKind: userKind, tierCode: tierCode, config: config), in: config)
    }

    /// A tier code may point at a plan the console forgot to define; never resolve to an undefined plan.
    private static func definedPlan(_ planID: PlanID, in config: PlansConfig) -> PlanID {
        config.plans[planID] == nil ? config.fallbackPlan : planID
    }

    private static func vpnType(from rawValue: String) -> VPNType? {
        VPNType(rawValue: rawValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())
    }
}
