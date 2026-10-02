//
//  RemoteConfigManager.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 24/04/2026.
//

import Foundation
import Combine
import FirebaseRemoteConfig

@MainActor
final class RemoteConfigManager: ObservableObject {
    static let shared = RemoteConfigManager()

    @Published private(set) var lastFetchStatus: RemoteConfigFetchAndActivateStatus?
    @Published private(set) var lastFetchError: Error?

    private let remoteConfig: RemoteConfig
    /// Decoded `builtin_vpn_config`, keyed by the raw value it came from, so decoding (and error reporting)
    /// happens once per activated value instead of on every launcher render.
    private var builtInVPNConfigCache: (raw: String, config: BuiltInVPNConfig)?
    /// Decoded `plans_config` by raw value (decode once per activation). Used by `RemoteConfigManager+Plans.swift`.
    var plansConfigCache: (raw: String, config: PlansConfig)?
    /// Last fetch queued through this manager; see `serializedFetch` (why fetches must not overlap).
    private var fetchQueueTail: Task<Void, Never>?
    /// Manual download page: Remote Config when fetch succeeded and value is valid; otherwise `MACOS_DOWNLOAD_URL` from Info.plist (xcconfig).
    var resolvedManualDownloadURL: URL? {
        if lastFetchError != nil {
            AppLogger.warning("RemoteConfig: fetch failed — using Info.plist MACOS_DOWNLOAD_URL for manual download")
            return AppUtils.macOSManualDownloadURL
        }
        let raw = resolvedAppUpdateConfig.macOSDownloadURL
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else {
            AppLogger.warning("RemoteConfig: macOSDownloadURL empty — using Info.plist MACOS_DOWNLOAD_URL")
            return AppUtils.macOSManualDownloadURL
        }
        guard let url = URL(string: raw),
              let scheme = url.scheme?.lowercased(),
              scheme == "https" || scheme == "http"
        else {
            AppLogger.warning("RemoteConfig: macOSDownloadURL invalid — using Info.plist MACOS_DOWNLOAD_URL")
            return AppUtils.macOSManualDownloadURL
        }
        return url
    }

    /// Parses `app_update_config` JSON from Remote Config
    var resolvedAppUpdateConfig: AppUpdateConfig {
        let raw = string(for: .appUpdateConfig).trimmingCharacters(in: .whitespacesAndNewlines)
        if !raw.isEmpty, let data = raw.data(using: .utf8) {
            do {
                let config = try JSONDecoder().decode(AppUpdateConfig.self, from: data)
                guard config.isSupported else {
                    AppLogger.warning(
                        """
                        RemoteConfig: app_update_config schemaVersion \(config.schemaVersion) is not \
                        supported (max \(AppUpdateConfig.supportedSchemaVersion)). Falling back to legacy keys.
                        """
                    )
                    return .default
                }
                return config
            } catch {
                AppLogger.warning(
                    "RemoteConfig: app_update_config decode failed — \(error). Falling back to legacy keys."
                )
                CrashReportingManager.shared.record(error: error)
            }
        }
        return .default
    }

    /// Parses `feature_flags_config` JSON from Remote Config
    var resolvedFeatureFlagsConfig: FeatureFlagsConfig {
        let raw = string(for: .featureFlagsConfig).trimmingCharacters(in: .whitespacesAndNewlines)
        if !raw.isEmpty, let data = raw.data(using: .utf8) {
            do {
                let config = try JSONDecoder().decode(FeatureFlagsConfig.self, from: data)
                guard config.isSupported else {
                    AppLogger.warning(
                        """
                        RemoteConfig: feature_flags_config schemaVersion \(config.schemaVersion) is not \
                        supported (max \(FeatureFlagsConfig.supportedSchemaVersion)). Falling back to legacy keys.
                        """
                    )
                    return .default
                }
                return config
            } catch {
                AppLogger.warning(
                    "RemoteConfig: feature_flags_config decode failed — \(error). Falling back to legacy keys."
                )
                CrashReportingManager.shared.record(error: error)
            }
        }
        return .default
    }

    /// Parses `endpoints_config` JSON from Remote Config
    var resolvedEndpointsConfig: EndpointsConfig {
        let raw = string(for: .endpointsConfig).trimmingCharacters(in: .whitespacesAndNewlines)
        if !raw.isEmpty, let data = raw.data(using: .utf8) {
            do {
                let config = try JSONDecoder().decode(EndpointsConfig.self, from: data)
                guard config.isSupported else {
                    AppLogger.warning(
                        """
                        RemoteConfig: endpoints_config schemaVersion \(config.schemaVersion) is not \
                        supported (max \(EndpointsConfig.supportedSchemaVersion)). Falling back to legacy keys.
                        """
                    )
                    return .default
                }
                return config
            } catch {
                AppLogger.warning(
                    "RemoteConfig: endpoints_config decode failed — \(error). Falling back to legacy keys."
                )
                CrashReportingManager.shared.record(error: error)
            }
        }
        return .default
    }

    // MARK: - URL Config Accessors
    var baseServerURL: String {
        normalizedURLString(resolvedEndpointsConfig.baseServerURL, fallback: "https://service.browserjet.com")
    }

    var baseWebURL: String {
        normalizedURLString(resolvedEndpointsConfig.baseWebURL, fallback: "https://browserjet.com")
    }

    var updateCardPath: String {
        normalizedPath(resolvedEndpointsConfig.serverPaths.updateCard, fallback: "/UpdateCard.aspx")
    }

    var buyMoreLicensesPath: String {
        normalizedPath(resolvedEndpointsConfig.serverPaths.buyMoreLicenses, fallback: "/MoreLicenses.aspx")
    }

    var browserPurchasePath: String {
        normalizedPath(resolvedEndpointsConfig.serverPaths.browserPurchase, fallback: "/BrowserPurchase.aspx")
    }

    var contactUsPath: String {
        normalizedPath(resolvedEndpointsConfig.webPaths.contactUs, fallback: "/contact")
    }

    var twitterURL: String {
        normalizedURLString(resolvedEndpointsConfig.externalLinks.twitter, fallback: "https://twitter.com/browserjet")
    }

    private func normalizedURLString(_ raw: String, fallback: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed),
              let scheme = url.scheme?.lowercased(),
              scheme == "https" || scheme == "http" else {
            return fallback
        }
        return trimmed
    }

    private func normalizedPath(_ raw: String, fallback: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return fallback }
        return trimmed.hasPrefix("/") ? trimmed : "/\(trimmed)"
    }

    // MARK: - Menu Config Accessor
    var menuConfiguration: MenuConfiguration {
        let raw = string(for: .menuConfig).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty, let data = raw.data(using: .utf8) else {
            return .default
        }
        do {
            let config = try JSONDecoder().decode(MenuConfiguration.self, from: data)
            guard config.isSupported else {
                AppLogger.warning(
                    """
                    RemoteConfig: menu_config schemaVersion \(config.schemaVersion) is not supported \
                    (max \(MenuConfiguration.supportedSchemaVersion)). Using default menu.
                    """
                )
                return .default
            }
            return config
        } catch {
            AppLogger.warning("RemoteConfig: menu_config decode failed — \(error). Using default menu.")
            CrashReportingManager.shared.record(error: error)
            return .default
        }
    }

    private init() {
        remoteConfig = RemoteConfig.remoteConfig()

        let settings = RemoteConfigSettings()
#if DEBUG
        settings.minimumFetchInterval = 0
#else
        settings.minimumFetchInterval = 3_600
#endif
        remoteConfig.configSettings = settings

        remoteConfig.setDefaults(Self.defaultValues())
    }
    /// Fetches from the server and applies activated values when appropriate.
    func fetchAndActivate() async {
        await serializedFetch { await self.performFetchAndActivate() }
    }
    
    // MARK: - Typed accessors
    func bool(for key: RemoteConfigKey) -> Bool {
        remoteConfig.configValue(forKey: key.rawValue).boolValue
    }

    func string(for key: RemoteConfigKey) -> String {
        remoteConfig.configValue(forKey: key.rawValue).stringValue
    }

    func number(for key: RemoteConfigKey) -> NSNumber {
        remoteConfig.configValue(forKey: key.rawValue).numberValue
    }

    func data(for key: RemoteConfigKey) -> Data {
        remoteConfig.configValue(forKey: key.rawValue).dataValue
    }
    // MARK: - Defaults
    private static func defaultValues() -> [String: NSObject] {
        var map: [String: NSObject] = [:]
        for key in RemoteConfigKey.allCases {
            map[key.rawValue] = defaultValue(for: key)
        }
        return map
    }

    private static func defaultValue(for key: RemoteConfigKey) -> NSObject {
        if let booleanDefault = booleanDefault(for: key) { return booleanDefault }
        return urlDefault(for: key)
    }

    private static func booleanDefault(for key: RemoteConfigKey) -> NSObject? {
        switch key {
        case .forceUpdateEnabled:
            return false as NSNumber
        default:
            return nil
        }
    }

    private static func urlDefault(for key: RemoteConfigKey) -> NSObject {
        switch key {
        case .appUpdateConfig:
            return AppUpdateConfig.defaultJSONString as NSString
        case .menuConfig:
            return MenuConfiguration.defaultJSONString as NSString
        case .featureFlagsConfig:
            return FeatureFlagsConfig.defaultJSONString as NSString
        case .endpointsConfig:
            return EndpointsConfig.defaultJSONString as NSString
        case .builtInVPNConfig:
            return BuiltInVPNConfig.defaultJSONString as NSString
        case .plansConfig:
            // Empty on purpose: `PlansConfig.default` (code) is the only in-app copy of the rules, used when empty.
            return "" as NSString
        default:
            return "" as NSString
        }
    }

    func debugPrintAllValues() {
        for key in RemoteConfigKey.allCases {
            let value = remoteConfig.configValue(forKey: key.rawValue)
            let printableValue = key.isSensitive
                ? "<redacted, \(value.stringValue.count) chars>"
                : value.stringValue
            AppLogger.debug("""
            🔹 \(key.rawValue)
            value: \(printableValue)
            source: \(value.source)
            """)
        }
    }
}

// MARK: - Fetch serialisation, forced fetch & custom signals (same file: uses the private `remoteConfig`)

extension RemoteConfigManager {
    /// Runs `operation` once every earlier queued fetch has finished. Why: Firebase answers a fetch issued while
    /// another runs with the *previous* result (no call, no error), so a forced fetch could "succeed" unsent.
    private func serializedFetch<T: Sendable>(_ operation: @escaping @MainActor @Sendable () async -> T) async -> T {
        let previous = fetchQueueTail
        let task = Task { @MainActor () -> T in
            await previous?.value
            return await operation()
        }
        fetchQueueTail = Task { @MainActor in _ = await task.value }
        return await task.value
    }

    /// The regular fetch (unchanged behaviour); always run through `serializedFetch`.
    private func performFetchAndActivate() async {
        lastFetchError = nil
        CrashReportingManager.shared.log("remote_config: fetch started")
        do {
            let status = try await remoteConfig.fetchAndActivate()
            lastFetchStatus = status
            CrashReportingManager.shared.log("remote_config: fetch succeeded - status \(status)")
        } catch {
            lastFetchError = error
            lastFetchStatus = nil
            AppLogger.warning("RemoteConfig: fetchAndActivate failed - \(error.localizedDescription)")
            CrashReportingManager.shared.log("remote_config: fetch failed - \(error.localizedDescription)")
        }
    }

    /// Fetches bypassing `minimumFetchInterval`, then activates; `true` only if the server was really asked.
    /// Why: Firebase doesn't re-fetch when a custom signal changes, so plan-targeted values (VPN pools) would lag a
    /// plan change by up to 1 h. Rare use only (Firebase throttles); on failure the active values stay as they are.
    @discardableResult
    func forceFetchAndActivate() async -> Bool {
        await serializedFetch { await self.performForcedFetchAndActivate() }
    }

    private func performForcedFetchAndActivate() async -> Bool {
        CrashReportingManager.shared.log("remote_config: forced fetch started")
        do {
            let status = try await remoteConfig.fetch(withExpirationDuration: 0)
            guard status == .success else {
                AppLogger.warning("RemoteConfig: forced fetch not completed - status \(status.rawValue)")
                CrashReportingManager.shared.log("remote_config: forced fetch incomplete - \(status.rawValue)")
                return false
            }
            let changed = try await remoteConfig.activate()
            // Publishing a new status re-renders observers (e.g. the launcher picks up newly served VPN pools).
            lastFetchError = nil
            lastFetchStatus = changed ? .successFetchedFromRemote : .successUsingPreFetchedData
            CrashReportingManager.shared.log("remote_config: forced fetch succeeded - changed \(changed)")
            return true
        } catch {
            AppLogger.warning("RemoteConfig: forced fetch failed - \(error.localizedDescription)")
            CrashReportingManager.shared.log("remote_config: forced fetch failed - \(error.localizedDescription)")
            return false
        }
    }

    /// Sets (or, with `nil`, removes) a string custom signal that Firebase console conditions can target.
    func setCustomSignal(_ key: String, to value: String?) async throws {
        try await remoteConfig.setCustomSignals([key: value.map { CustomSignalValue.string($0) }])
    }
}

// MARK: - Built-in VPN pools

extension RemoteConfigManager: ProxyPoolTemplateProviding {
    func proxyPoolTemplate(forVPNID vpnID: String) -> ProxyPoolTemplate? {
        resolvedBuiltInVPNConfig.pools[vpnID]
    }

    /// Parses `builtin_vpn_config` JSON from Remote Config. Falls back to `.default` (no pools) on any failure,
    /// which leaves built-in VPN unavailable rather than guessing credentials.
    var resolvedBuiltInVPNConfig: BuiltInVPNConfig {
        let raw = string(for: .builtInVPNConfig).trimmingCharacters(in: .whitespacesAndNewlines)
        if let cache = builtInVPNConfigCache, cache.raw == raw {
            return cache.config
        }
        let config = decodeBuiltInVPNConfig(from: raw)
        builtInVPNConfigCache = (raw: raw, config: config)
        return config
    }

    private func decodeBuiltInVPNConfig(from raw: String) -> BuiltInVPNConfig {
        guard !raw.isEmpty, let data = raw.data(using: .utf8) else {
            return .default
        }
        do {
            let config = try JSONDecoder().decode(BuiltInVPNConfig.self, from: data)
            guard config.isSupported else {
                AppLogger.warning(
                    """
                    RemoteConfig: builtin_vpn_config schemaVersion \(config.schemaVersion) is not supported \
                    (max \(BuiltInVPNConfig.supportedSchemaVersion)). Built-in VPN unavailable.
                    """
                )
                return .default
            }
            AppLogger.info("RemoteConfig: builtin_vpn_config loaded - \(config.pools.count) pool(s)")
            return config
        } catch {
            AppLogger.warning("RemoteConfig: builtin_vpn_config decode failed — \(error). Built-in VPN unavailable.")
            CrashReportingManager.shared.record(error: error)
            return .default
        }
    }
}
