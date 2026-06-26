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
                AppLogger.warning("RemoteConfig: app_update_config decode failed — \(error). Falling back to legacy keys.")
            }
        }
        return .default
    }
    
    // MARK: - URL Config Accessors
    var baseServerURL: String {
        normalizedURLString(for: .baseServerURL, fallback: "https://service.browserjet.com")
    }
    
    var baseWebURL: String {
        normalizedURLString(for: .baseWebURL, fallback: "https://browserjet.com")
    }
    
    var updateCardPath: String {
        normalizedPath(for: .updateCardPath, fallback: "/UpdateCard.aspx")
    }
    
    var buyMoreLicensesPath: String {
        normalizedPath(for: .buyMoreLicensesPath, fallback: "/MoreLicenses.aspx")
    }
    
    var contactUsPath: String {
        normalizedPath(for: .contactUsPath, fallback: "/contact")
    }
    
    var twitterURL: String {
        normalizedURLString(for: .twitterURL, fallback: "https://twitter.com/browserjet")
    }
    
    private func normalizedURLString(for key: RemoteConfigKey, fallback: String) -> String {
        let raw = string(for: key).trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: raw),
              let scheme = url.scheme?.lowercased(),
              scheme == "https" || scheme == "http" else {
            return fallback
        }
        return raw
    }
    
    private func normalizedPath(for key: RemoteConfigKey, fallback: String) -> String {
        let raw = string(for: key).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else { return fallback }
        return raw.hasPrefix("/") ? raw : "/\(raw)"
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
        lastFetchError = nil
        do {
            let status = try await remoteConfig.fetchAndActivate()
            lastFetchStatus = status
        } catch {
            lastFetchError = error
            lastFetchStatus = nil
        }
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
        case .shortcutsEnabled:
            return true as NSNumber
        default:
            return nil
        }
    }
    
    private static func urlDefault(for key: RemoteConfigKey) -> NSObject {
        switch key {
        case .appUpdateConfig:
            return AppUpdateConfig.defaultJSONString as NSString
        case .baseServerURL:
            return "https://service.browserjet.com" as NSString
        case .baseWebURL:
            return "https://browserjet.com" as NSString
        case .updateCardPath:
            return "/UpdateCard.aspx" as NSString
        case .buyMoreLicensesPath:
            return "/MoreLicenses.aspx" as NSString
        case .contactUsPath:
            return "/contact" as NSString
        case .twitterURL:
            return "https://twitter.com/browserjet" as NSString
        case .menuConfig:
            return MenuConfiguration.defaultJSONString as NSString
        default:
            // The earlier helpers exhaustively handle the boolean/version cases.
            return "" as NSString
        }
    }
    
    func debugPrintAllValues() {
        for key in RemoteConfigKey.allCases {
            let value = remoteConfig.configValue(forKey: key.rawValue)
            AppLogger.debug("""
            🔹 \(key.rawValue)
            value: \(value.stringValue)
            source: \(value.source)
            """)
        }
    }
}
