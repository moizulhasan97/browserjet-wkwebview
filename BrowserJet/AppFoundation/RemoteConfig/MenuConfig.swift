//
//  MenuConfig.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 30/06/2026.
//

import Foundation

struct MenuConfig: Decodable, Sendable {
    /// Remote Config controls visibility, order, and trial-lock availability only.
    /// Display titles and tooltips remain on `BrowserToolbarAction` / `BrowserMoreMenuItem`.
    let schemaVersion: Int
    let trailingToolbarItems: [Item]
    let moreMenuItems: [Item]

    struct Item: Decodable, Sendable {
        let id: String
        let enabled: Bool
        let order: Int
        let availableWhenTrialLocked: Bool
    }

    static let `default` = MenuConfig(
        schemaVersion: 1,
        trailingToolbarItems: [
            Item(id: "new_tab", enabled: true, order: 1, availableWhenTrialLocked: false),
            Item(id: "burn_ip_reload", enabled: true, order: 2, availableWhenTrialLocked: false),
            Item(id: "duplicate_tab", enabled: true, order: 3, availableWhenTrialLocked: false),
            Item(id: "refresh_all_tabs", enabled: true, order: 4, availableWhenTrialLocked: false),
            Item(id: "screenshot", enabled: true, order: 5, availableWhenTrialLocked: true)
        ],
        moreMenuItems: [
            Item(id: "payment_card", enabled: true, order: 1, availableWhenTrialLocked: false),
            Item(id: "buy_more_licenses", enabled: true, order: 2, availableWhenTrialLocked: false),
            Item(id: "contact_us", enabled: true, order: 3, availableWhenTrialLocked: true),
            Item(id: "change_key", enabled: true, order: 4, availableWhenTrialLocked: true),
            Item(id: "twitter", enabled: true, order: 5, availableWhenTrialLocked: true)
        ]
    )

    static func decode(from json: String) -> MenuConfig? {
        let trimmed = json.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let data = trimmed.data(using: .utf8) else {
            return nil
        }

        guard let decoded = try? JSONDecoder().decode(MenuConfig.self, from: data),
              decoded.schemaVersion == 1 else {
            return nil
        }

        return decoded
    }
}
