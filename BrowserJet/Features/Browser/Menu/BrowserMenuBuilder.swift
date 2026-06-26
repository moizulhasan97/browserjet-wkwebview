//
//  BrowserMenuBuilder.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 16/02/2026.
//

import Foundation

struct MoreMenuEntry: Hashable {
    let item: BrowserMoreMenuItem
    let title: String
    let tooltip: String
    let availableWhenTrialLocked: Bool
}

struct TrailingToolbarEntry: Hashable {
    let action: BrowserToolbarAction
    let tooltip: String
    let availableWhenTrialLocked: Bool
}

// MARK: - Menu builder
struct BrowserMenuBuilder {
    var leading: [BrowserToolbarAction]
    var trailingEntries: [TrailingToolbarEntry]
    var moreMenuEntries: [MoreMenuEntry]
    
    // Convenience for callers that only need the action list
    var trailing: [BrowserToolbarAction] { trailingEntries.map(\.action) }
    
    // Actions allowed even when the trial is locked
    var trialAllowedToolbarActions: Set<BrowserToolbarAction> {
        var allowed: Set<BrowserToolbarAction> = [.back, .forward, .reload, .stop]
        for entry in trailingEntries where entry.availableWhenTrialLocked {
            allowed.insert(entry.action)
        }
        return allowed
    }
    
    func isMoreMenuItemAllowedWhenTrialLocked(_ item: BrowserMoreMenuItem) -> Bool {
        visibleMoreMenuEntries(isTrialLocked: true).contains { $0.item == item }
    }
    
    // Returns only the more-menu entries that should be visible
    // given the current trial-lock state.
    func visibleMoreMenuEntries(isTrialLocked: Bool) -> [MoreMenuEntry] {
        guard isTrialLocked else { return moreMenuEntries }
        return moreMenuEntries.filter(\.availableWhenTrialLocked)
    }
    
    static func from(_ config: MenuConfiguration) -> BrowserMenuBuilder {
        let sorted = config.items
            .filter { $0.enabled }
            .sorted { $0.order < $1.order }
        
        let trailingEntries: [TrailingToolbarEntry] = sorted.compactMap { item in
            guard let knownID = item.knownID,
                  let action = knownID.toolbarAction else { return nil }
            return TrailingToolbarEntry(
                action: action,
                tooltip: item.resolvedTooltip,
                availableWhenTrialLocked: item.availableWhenTrialLocked
            )
        }
        
        let moreMenuEntries: [MoreMenuEntry] = sorted.compactMap { item in
            guard let knownID = item.knownID,
                  let menuItem = knownID.moreMenuItem else { return nil }
            return MoreMenuEntry(
                item: menuItem,
                title: item.title,
                tooltip: item.resolvedTooltip,
                availableWhenTrialLocked: item.availableWhenTrialLocked
            )
        }
        
        return BrowserMenuBuilder(
            leading: [.back, .forward, .reload],
            trailingEntries: trailingEntries,
            moreMenuEntries: moreMenuEntries
        )
    }
    
    // MARK: - Static instances
    // Derived from the compile-time fallback; replaced at runtime by
    // WindowManager using RemoteConfigManager.shared.menuConfiguration.
    static let `default` = BrowserMenuBuilder.from(.default)
}
