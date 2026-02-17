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
    
    init(
        address: String,
        numberOfTabs: Int,
        proxyType: ProxyType,
        isolationMode: SessionIsolationMode,
        userAgent: String? = nil
    ) {
        self.address = address
        self.numberOfTabs = numberOfTabs
        self.proxyType = proxyType
        self.isolationMode = isolationMode
        self.userAgent = userAgent
    }
}
