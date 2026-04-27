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
    
    /// Safety fallback if firebase fails or key is missing in Remote Config
    private static func defaultValue(for key: RemoteConfigKey) -> NSObject {
        switch key {
        case .forceUpdateEnabled:
            return false as NSNumber
            
        case .optionalUpdateEnabled:
            return false as NSNumber
            
        case .macOSAppLatestMarketingVersion:
            return AppUtils.getAppMarketingVersion() as NSString
            
        case .macOSAppMinimumSupportedMarketingVersion:
            return "1.0.0" as NSString
            
        case .macOSAppLatestBuildVersion:
            return AppUtils.getAppBuildVersion() as NSNumber
            
        case .macOSAppMinimumSupportedBuildVersion:
            return 0 as NSNumber
        }
    }
    
    func debugPrintAllValues() {
        for key in RemoteConfigKey.allCases {
            let value = remoteConfig.configValue(forKey: key.rawValue)
            print("""
            🔹 \(key.rawValue)
            value: \(value.stringValue ?? "nil")
            source: \(value.source)
            """)
        }
    }
}
