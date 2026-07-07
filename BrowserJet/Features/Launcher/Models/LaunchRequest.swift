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
    let proxyType: ProxyType
    let isolationMode: SessionIsolationMode
    let userAgent: String?
    let selectedVPN: VPNType?
    let rotationMethod: ProxyRotationType
    let customProxies: [AuthProxy]
    
    init(
        address: String,
        numberOfTabs: Int,
        proxyType: ProxyType,
        isolationMode: SessionIsolationMode,
        userAgent: String? = nil,
        selectedVPN: VPNType? = nil,
        rotationMethod: ProxyRotationType = .linear,
        customProxies: [AuthProxy] = []
    ) {
        self.address = address
        self.numberOfTabs = numberOfTabs
        self.proxyType = proxyType
        self.isolationMode = isolationMode
        self.userAgent = userAgent
        self.selectedVPN = selectedVPN
        self.rotationMethod = rotationMethod
        self.customProxies = customProxies
    }
}
