//
//  LaunchRequest.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 17/02/2026.
//

import Foundation

struct LaunchRequest: Hashable {
    let address: String
    let numberOfTabs: Int
    /// The plan's tab limit captured at launch. The window keeps it for its lifetime, so a plan change detected
    /// mid-session (background licence re-check) applies on the next launch instead of disrupting open tabs.
    let maxTabs: Int
    let proxyType: ProxyType
    let isolationMode: SessionIsolationMode
    let userAgent: String?

    init(
        address: String,
        numberOfTabs: Int,
        maxTabs: Int,
        proxyType: ProxyType,
        isolationMode: SessionIsolationMode,
        userAgent: String? = nil
    ) {
        self.address = address
        self.numberOfTabs = numberOfTabs
        self.maxTabs = maxTabs
        self.proxyType = proxyType
        self.isolationMode = isolationMode
        self.userAgent = userAgent
    }
}
