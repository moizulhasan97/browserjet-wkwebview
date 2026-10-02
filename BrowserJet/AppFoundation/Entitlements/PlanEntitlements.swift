//
//  PlanEntitlements.swift
//  BrowserJet
//

import Foundation

/// What the user's plan unlocks.
///
/// Why this exists: before packages, tab limits and VPN access were app-wide constants in `AppConfiguration`
/// (`maxBrowserTabs`, `trialBlockedVPNs`). Basic / Pro / Trial now differ, so every plan-gated decision
/// (launcher, launch request, browser window, About) reads this one value, resolved from the licence plus
/// Remote Config `plans_config`. Changing a plan's rules is then a Firebase edit, not a release.
struct PlanEntitlements: Equatable {
    /// Compile-time ceiling for tabs in one window, whatever Remote Config says.
    /// Why: a console typo (e.g. `maxTabs: 300`) must not spawn hundreds of WKWebView processes. It also sizes
    /// `SessionManager`, which is created at app start, before the licence (and therefore the plan) is known.
    static let absoluteMaxTabs = 50

    let planID: PlanID
    /// Marketing name shown in About (e.g. "Captain - Pro").
    let displayName: String
    let maxTabs: Int
    /// Allowlist rather than a blocklist: a VPN tier added to the app later stays off for every plan
    /// until Remote Config explicitly grants it (fail closed).
    let allowedVPNs: Set<VPNType>
    /// Whether the plan may use Premium Proxy (GPP). Actual availability still depends on the user having
    /// purchased GPP rows from the backend.
    let isPremiumProxyAllowed: Bool

    init(
        planID: PlanID,
        displayName: String,
        maxTabs: Int,
        allowedVPNs: Set<VPNType>,
        isPremiumProxyAllowed: Bool
    ) {
        self.planID = planID
        self.displayName = displayName
        self.maxTabs = Self.clampedTabCount(maxTabs)
        self.allowedVPNs = allowedVPNs
        self.isPremiumProxyAllowed = isPremiumProxyAllowed
    }

    func allows(_ vpn: VPNType) -> Bool {
        allowedVPNs.contains(vpn)
    }

    /// Launch-time check, used as defence in depth behind the launcher UI.
    func allows(_ proxyType: ProxyType) -> Bool {
        switch proxyType {
        case .local:
            return true
        case .proxy(.builtIn(let vpn, _)):
            return allows(vpn)
        case .proxy(.premium):
            return isPremiumProxyAllowed
        case .proxy(.custom):
            // No plan grants custom proxies yet; fail closed until one does.
            return false
        }
    }

    /// Keeps any configured value inside `1...absoluteMaxTabs`.
    static func clampedTabCount(_ value: Int) -> Int {
        min(max(1, value), absoluteMaxTabs)
    }
}

extension PlanEntitlements {
    /// Last-resort entitlements if a plan can't be resolved at all (should be unreachable with a validated
    /// config). Deliberately minimal so a broken configuration can never grant more than a user paid for.
    static func restricted(planID: PlanID) -> PlanEntitlements {
        PlanEntitlements(
            planID: planID,
            displayName: "",
            maxTabs: 1,
            allowedVPNs: [],
            isPremiumProxyAllowed: false
        )
    }
}
