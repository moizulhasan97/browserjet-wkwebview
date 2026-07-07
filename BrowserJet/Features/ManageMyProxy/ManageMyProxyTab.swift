//
//  ManageMyProxyTab.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 07/07/2026.
//


enum ManageMyProxyTab: String, CaseIterable, Hashable, Identifiable {
    case manageProxies = "Manage Proxies"
    case addProxies = "Add Proxies"

    var id: String { rawValue }
}