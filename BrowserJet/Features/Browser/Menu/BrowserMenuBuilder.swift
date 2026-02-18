//
//  BrowserMenuBuilder.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 16/02/2026.
//


import Foundation

struct BrowserMenuBuilder {
    var leading: [BrowserToolbarAction]
    var trailing: [BrowserToolbarAction]

    static let `default` = BrowserMenuBuilder(
        leading: [.back, .forward, .reload],
        trailing: [.vpnIndicator, .favorites, .newTab, .downloads, .history, .settings]
    )
}
