//
//  LauncherMessages.swift
//  BrowserJet
//

import Foundation

enum LauncherMessages {
    /// Shown when built-in VPN is on but its pool has not been delivered by Remote Config (e.g. offline first launch).
    static let vpnUnavailable = "VPN is unavailable right now. Please check your internet connection and try again."

    /// Shown when the user turns Premium Proxy on but the GPP list is empty (fetch failed, still loading, or no rows).
    static let premiumNoProxiesAvailable = "No premium proxies are available."
}
