//
//  LauncherMessages.swift
//  BrowserJet
//

import Foundation

enum LauncherMessages {
    /// Shown to trial users when some VPN tiers are reserved for paid plans (see `AppConfiguration.trialBlockedVPNs`).
    static let trialPaidVpnFootnote = "VPN 1 is only available on a paid plan."

    /// Shown when the user turns Premium Proxy on but the GPP list is empty (fetch failed, still loading, or no rows).
    static let premiumNoProxiesAvailable = "No premium proxies are available."
}
