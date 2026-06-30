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

    static let `default` = from(config: .default, isTrialLocked: false)

    static func from(config: MenuConfig, isTrialLocked: Bool) -> BrowserMenuBuilder {
        BrowserMenuBuilder(
            leading: [.back, .forward, .reload],
            trailing: resolveTrailingToolbar(from: config, isTrialLocked: isTrialLocked),
            moreMenuItems: resolveMoreMenu(from: config, isTrialLocked: isTrialLocked)
        )
    }

    private static func resolveTrailingToolbar(
        from config: MenuConfig,
        isTrialLocked: Bool
    ) -> [BrowserToolbarAction] {
        resolve(
            defaults: defaultTrailingItems,
            configItems: config.trailingToolbarItems,
            isTrialLocked: isTrialLocked
        )
    }

    private static func resolveMoreMenu(
        from config: MenuConfig,
        isTrialLocked: Bool
    ) -> [BrowserMoreMenuItem] {
        resolve(
            defaults: defaultMoreMenuItems,
            configItems: config.moreMenuItems,
            isTrialLocked: isTrialLocked
        )
    }

    private struct DefaultItem<Action> {
        let id: String
        let action: Action
        let defaultOrder: Int
        let defaultAvailableWhenTrialLocked: Bool
    }

    private static let defaultTrailingItems: [DefaultItem<BrowserToolbarAction>] = [
        DefaultItem(id: "new_tab", action: .newTab, defaultOrder: 1, defaultAvailableWhenTrialLocked: false),
        DefaultItem(id: "burn_ip_reload", action: .burnProxyAndReload, defaultOrder: 2, defaultAvailableWhenTrialLocked: false),
        DefaultItem(id: "duplicate_tab", action: .duplicateToTabsMenu, defaultOrder: 3, defaultAvailableWhenTrialLocked: false),
        DefaultItem(id: "refresh_all_tabs", action: .refreshAllTabs, defaultOrder: 4, defaultAvailableWhenTrialLocked: false),
        DefaultItem(id: "screenshot", action: .screenshot, defaultOrder: 5, defaultAvailableWhenTrialLocked: true)
    ]

    private static let defaultMoreMenuItems: [DefaultItem<BrowserMoreMenuItem>] = [
        DefaultItem(id: "payment_card", action: .paymentCard, defaultOrder: 1, defaultAvailableWhenTrialLocked: false),
        DefaultItem(id: "buy_more_licenses", action: .buyLicenses, defaultOrder: 2, defaultAvailableWhenTrialLocked: false),
        DefaultItem(id: "contact_us", action: .contactUs, defaultOrder: 3, defaultAvailableWhenTrialLocked: true),
        DefaultItem(id: "change_key", action: .changeKey, defaultOrder: 4, defaultAvailableWhenTrialLocked: true),
        DefaultItem(id: "twitter", action: .twitter, defaultOrder: 5, defaultAvailableWhenTrialLocked: true)
    ]

    private static func resolve<Action>(
        defaults: [DefaultItem<Action>],
        configItems: [MenuConfig.Item],
        isTrialLocked: Bool
    ) -> [Action] {
        let configByID = Dictionary(uniqueKeysWithValues: configItems.map { ($0.id, $0) })

        let resolved = defaults.compactMap { defaultItem -> (order: Int, action: Action)? in
            let remote = configByID[defaultItem.id]
            let enabled = remote?.enabled ?? true
            let availableWhenTrialLocked = remote?.availableWhenTrialLocked ?? defaultItem.defaultAvailableWhenTrialLocked
            let order = remote?.order ?? defaultItem.defaultOrder

            guard enabled else { return nil }
            if isTrialLocked, !availableWhenTrialLocked { return nil }
            return (order, defaultItem.action)
        }

        return resolved
            .sorted { $0.order < $1.order }
            .map(\.action)
    }
}
