//
//  RemoteConfigManager+Plans.swift
//  BrowserJet
//

import Foundation

// MARK: - Plans (`plans_config`)

extension RemoteConfigManager: PlansConfigProviding {
    /// Parses `plans_config`. Falls back to `PlansConfig.default` on an empty value, unsupported schema, decode
    /// failure or a config that fails validation, so a bad console edit can never unlock more than the in-app rules.
    var resolvedPlansConfig: PlansConfig {
        let raw = string(for: .plansConfig).trimmingCharacters(in: .whitespacesAndNewlines)
        if let cache = plansConfigCache, cache.raw == raw {
            return cache.config
        }
        let config = decodePlansConfig(from: raw)
        plansConfigCache = (raw: raw, config: config)
        return config
    }

    private func decodePlansConfig(from raw: String) -> PlansConfig {
        guard !raw.isEmpty, let data = raw.data(using: .utf8) else {
            return .default
        }
        do {
            let config = try JSONDecoder().decode(PlansConfig.self, from: data)
            guard config.isSupported else {
                AppLogger.warning(
                    """
                    RemoteConfig: plans_config schemaVersion \(config.schemaVersion) is not supported \
                    (max \(PlansConfig.supportedSchemaVersion)). Using in-app plans.
                    """
                )
                return .default
            }
            guard config.isValid else {
                AppLogger.warning(
                    "RemoteConfig: plans_config fallbackPlan/trialPlan missing from plans. Using in-app plans."
                )
                return .default
            }
            AppLogger.info("RemoteConfig: plans_config loaded - \(config.plans.count) plan(s)")
            return config
        } catch {
            AppLogger.warning("RemoteConfig: plans_config decode failed — \(error). Using in-app plans.")
            CrashReportingManager.shared.record(error: error)
            return .default
        }
    }
}
