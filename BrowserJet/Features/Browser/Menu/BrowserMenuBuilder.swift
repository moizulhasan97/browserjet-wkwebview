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
    var moreMenuItems: [BrowserMoreMenuItem]
    
    static let `default` = BrowserMenuBuilder(
        leading: [.back, .forward, .reload],
        trailing: [.newTab, .burnProxyAndReload, .duplicateToTabsMenu, .refreshAllTabs, .accountManager, .screenshot],
        moreMenuItems: [.paymentCard, .buyLicenses, .contactUs, .changeKey, .about, .twitter]
    )
}
