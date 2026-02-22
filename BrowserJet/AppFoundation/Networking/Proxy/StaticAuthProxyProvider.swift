//
//  StaticAuthProxyProvider.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 22/02/2026.
//


import Foundation

struct StaticAuthProxyProvider: AuthProxyProvider {
    let proxies: [AuthProxy]
    func loadPool() -> [AuthProxy] { proxies }
}