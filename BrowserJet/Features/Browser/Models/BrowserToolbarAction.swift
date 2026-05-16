//
//  BrowserToolbarAction.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 16/02/2026.
//

import Foundation

enum BrowserToolbarAction: Hashable {
    case back
    case forward
    case reload
    case stop
    case newTab
    case burnProxyAndReload
    case duplicateToTabsMenu
    case refreshAllTabs
    case accountManager
    case screenshot
}

extension BrowserToolbarAction {
    var systemImageName: String {
        switch self {
        case .back: return "chevron.left"
        case .forward: return "chevron.right"
        case .reload: return "arrow.clockwise"
        case .stop:   return "xmark"
        case .newTab: return "plus"
        case .burnProxyAndReload:  return "arrow.triangle.2.circlepath"
        case .duplicateToTabsMenu: return "square.on.square"
        case .refreshAllTabs:      return "arrow.clockwise"
        case .accountManager:      return "person.2"
        case .screenshot:          return "viewfinder"
        }
    }

    var accessibilityTitle: String {
        switch self {
        case .back: return "Back"
        case .forward: return "Forward"
        case .reload: return "Reload"
        case .stop:   return "Stop"
        case .newTab: return "New Tab"
        case .burnProxyAndReload:  return "Burn IP and reload"
        case .duplicateToTabsMenu: return "Duplicate tab"
        case .refreshAllTabs:      return "Refresh all tabs"
        case .accountManager:      return "Account manager"
        case .screenshot:          return "Screenshot"
        }
    }

    var tooltip: String {
        accessibilityTitle
    }
}
