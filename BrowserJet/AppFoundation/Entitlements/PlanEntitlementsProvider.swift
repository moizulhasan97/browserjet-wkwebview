//
//  PlanEntitlementsProvider.swift
//  BrowserJet
//

import Foundation

/// Source of the decoded Remote Config `plans_config`. `RemoteConfigManager` conforms; tests can inject a
/// fixed config instead of talking to Firebase.
@MainActor
protocol PlansConfigProviding: AnyObject {
    var resolvedPlansConfig: PlansConfig { get }
}

/// Resolves the signed-in user's current entitlements. Injected into view models so plan rules can be faked.
@MainActor
protocol PlanEntitlementsProviding {
    func currentEntitlements() -> PlanEntitlements
}

/// Live provider: licence facts from `LicenseAccountStore` + plan rules from Remote Config.
///
/// Computed on demand (the decoded config is cached by `RemoteConfigManager`) so the launcher always
/// reflects the latest licence refresh and Remote Config activation. An open browser window does not use
/// this: it keeps the limits it launched with, so a mid-session plan change applies on the next launch.
@MainActor
struct LicensePlanEntitlementsProvider: PlanEntitlementsProviding {
    private let accountStore: LicenseAccountStore
    private let plansConfigSource: PlansConfigProviding

    init(
        accountStore: LicenseAccountStore? = nil,
        plansConfigSource: PlansConfigProviding? = nil
    ) {
        self.accountStore = accountStore ?? .shared
        self.plansConfigSource = plansConfigSource ?? RemoteConfigManager.shared
    }

    func currentEntitlements() -> PlanEntitlements {
        PlanResolver.entitlements(
            userKind: accountStore.userKind,
            tierCode: accountStore.tierRawValue,
            config: plansConfigSource.resolvedPlansConfig
        )
    }
}
