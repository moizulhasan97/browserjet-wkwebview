//
//  PlanSignalSynchronizer.swift
//  BrowserJet
//

import Foundation

/// Remote Config operations the plan-signal sync needs. `RemoteConfigManager` conforms; tests can fake it.
@MainActor
protocol PlanSignalTargeting: PlansConfigProviding {
    func setCustomSignal(_ key: String, to value: String?) async throws
    func forceFetchAndActivate() async -> Bool
}

extension RemoteConfigManager: PlanSignalTargeting {}

/// Keeps the Remote Config `plan` custom signal in step with the user's licence.
///
/// Why: Firebase console conditions on `plan` decide who is served plan-restricted values, above all the VPN
/// credentials in `builtin_vpn_config`, which only Pro should download. Firebase persists the signal across
/// launches but does not re-fetch when it changes, so a change forces one fetch.
@MainActor
final class PlanSignalSynchronizer {
    static let shared = PlanSignalSynchronizer()

    /// Custom signal key that Firebase console conditions target (e.g. `plan == pro`).
    static let signalKey = "plan"
    /// Wait after a failed forced fetch before trying again. Why: the licence monitor syncs on every poll (10 s);
    /// without a back-off an offline or throttled client would force-fetch every poll and get throttled harder.
    static let retryBackoffInterval: TimeInterval = 5 * 60

    private let remoteConfig: PlanSignalTargeting
    private let store: KeyValueStoring
    private let now: () -> Date
    private var isSyncing = false
    /// Latest plan that arrived while a sync was running; applied as soon as that sync finishes.
    private var pendingPlanID: PlanID?
    /// Back-off after a failed forced fetch, per plan, so a different plan arriving meanwhile isn't delayed.
    private var retryBackoff: (planID: PlanID, notBefore: Date)?

    init(
        remoteConfig: PlanSignalTargeting? = nil,
        store: KeyValueStoring? = nil,
        now: @escaping () -> Date = Date.init
    ) {
        self.remoteConfig = remoteConfig ?? RemoteConfigManager.shared
        self.store = store ?? UserDefaultsKeyValueStore()
        self.now = now
    }

    /// Reports the plan of the currently persisted licence. Call after every licence save.
    ///
    /// Fire-and-forget so licence flows (activation, background re-check) never wait on a network round-trip;
    /// observers such as the launcher update when the forced fetch activates.
    func syncWithCurrentLicense(entitlementsProvider: PlanEntitlementsProviding? = nil) {
        let provider = entitlementsProvider ?? LicensePlanEntitlementsProvider(plansConfigSource: remoteConfig)
        let planID = provider.currentEntitlements().planID
        Task { await apply(planID) }
    }

    /// Sets the signal and, when it differs from the last plan whose values were successfully fetched, forces a
    /// fetch + activate so plan-restricted values are added (upgrade) or dropped (downgrade) straight away.
    func apply(_ planID: PlanID) async {
        // One sync at a time; overlapping requests are coalesced so only the latest plan runs next.
        guard !isSyncing else {
            pendingPlanID = planID
            return
        }
        isSyncing = true
        await sync(planID)
        isSyncing = false

        if let next = pendingPlanID {
            pendingPlanID = nil
            await apply(next)
        }
    }

    private func sync(_ planID: PlanID) async {
        do {
            try await remoteConfig.setCustomSignal(Self.signalKey, to: planID.rawValue)
        } catch {
            AppLogger.warning("PlanSignalSynchronizer: failed to set plan signal - \(error.localizedDescription)")
            CrashReportingManager.shared.record(error: error)
            return
        }

        // Persisted because Firebase exposes no getter for signals, and only a *change* justifies a forced fetch.
        // Written only after a successful fetch, so a failed one is retried (after the back-off, or next launch).
        let lastFetchedPlan = store.object(forKey: StorageKeys.remoteConfigPlanSignal) as? String
        guard lastFetchedPlan != planID.rawValue else {
            retryBackoff = nil
            return
        }
        if let retryBackoff, retryBackoff.planID == planID, now() < retryBackoff.notBefore { return }

        AppLogger.info(
            "PlanSignalSynchronizer: plan changed (\(lastFetchedPlan ?? "none") -> \(planID.rawValue)) - forcing fetch"
        )
        if await remoteConfig.forceFetchAndActivate() {
            store.set(planID.rawValue, forKey: StorageKeys.remoteConfigPlanSignal)
            retryBackoff = nil
        } else {
            retryBackoff = (planID: planID, notBefore: now().addingTimeInterval(Self.retryBackoffInterval))
        }
    }
}
