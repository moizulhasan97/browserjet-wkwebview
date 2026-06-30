//
//  MenuConfiguration.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 26/06/2026.
//

import Foundation

struct MenuConfiguration: Decodable {
    /// Highest menu_config schema version this app build understands.
    static let supportedSchemaVersion = 1

    let schemaVersion: Int
    let items: [MenuItemConfiguration]

    var isSupported: Bool {
        schemaVersion <= Self.supportedSchemaVersion
    }

    init(schemaVersion: Int = 1, items: [MenuItemConfiguration]) {
        self.schemaVersion = schemaVersion
        self.items = items
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 1
        items = try container.decode([MenuItemConfiguration].self, forKey: .items)
    }

    private enum CodingKeys: String, CodingKey {
        case schemaVersion
        case items
    }
}

struct MenuItemConfiguration: Decodable {
    let id: String
    let title: String
    let tooltip: String?
    let enabled: Bool
    let order: Int
    let availableWhenTrialLocked: Bool

    /// Remote tooltip when set; otherwise falls back to `title`.
    var resolvedTooltip: String {
        let trimmed = tooltip?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? title : trimmed
    }

    init(
        id: String,
        title: String,
        tooltip: String?,
        enabled: Bool,
        order: Int,
        availableWhenTrialLocked: Bool
    ) {
        self.id = id
        self.title = title
        self.tooltip = tooltip
        self.enabled = enabled
        self.order = order
        self.availableWhenTrialLocked = availableWhenTrialLocked
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        tooltip = try container.decodeIfPresent(String.self, forKey: .tooltip)
        enabled = try container.decode(Bool.self, forKey: .enabled)
        order = try container.decode(Int.self, forKey: .order)

        if let available = try container.decodeIfPresent(Bool.self, forKey: .availableWhenTrialLocked) {
            availableWhenTrialLocked = available
        } else if let legacyRequiresUnlock = try container.decodeIfPresent(Bool.self, forKey: .requiresTrialUnlock) {
            availableWhenTrialLocked = !legacyRequiresUnlock
        } else {
            availableWhenTrialLocked = false
        }
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case tooltip
        case enabled
        case order
        case availableWhenTrialLocked
        case requiresTrialUnlock
    }
}

extension MenuItemConfiguration {
    enum KnownID: String {
        // Trailing toolbar
        case newTab          = "new_tab"
        case burnIPReload    = "burn_ip_reload"
        case duplicateTab    = "duplicate_tab"
        case refreshAllTabs  = "refresh_all_tabs"
        case screenshot      = "screenshot"
        // More menu
        case paymentCard     = "payment_card"
        case buyMoreLicenses = "buy_more_licenses"
        case contactUs       = "contact_us"
        case changeKey       = "change_key"
        case twitter         = "twitter"
    }
    
    var knownID: KnownID? {
        KnownID(rawValue: id)
    }
}

extension MenuItemConfiguration.KnownID {
    var toolbarAction: BrowserToolbarAction? {
        switch self {
        case .newTab:         return .newTab
        case .burnIPReload:   return .burnProxyAndReload
        case .duplicateTab:   return .duplicateToTabsMenu
        case .refreshAllTabs: return .refreshAllTabs
        case .screenshot:     return .screenshot
        default:              return nil
        }
    }
    
    var moreMenuItem: BrowserMoreMenuItem? {
        switch self {
        case .paymentCard:     return .paymentCard
        case .buyMoreLicenses: return .buyLicenses
        case .contactUs:       return .contactUs
        case .changeKey:       return .changeKey
        case .twitter:         return .twitter
        default:               return nil
        }
    }
}

// MARK: - Compile-time fallback (mirrors the current hardcoded menu)
extension MenuConfiguration {
    // Used as the Firebase Remote Config registered default and as the
    // in-app fallback when the fetch fails or returns an empty value.
    static let defaultJSONString = """
    {
      "schemaVersion": 1,
      "items": [
        {
          "id": "new_tab",
          "title": "New Tab",
          "tooltip": "Open a new browser tab.",
          "enabled": true,
          "order": 1,
          "availableWhenTrialLocked": false
        },
        {
          "id": "burn_ip_reload",
          "title": "Burn IP and Reload",
          "tooltip": "Switch to the next available IP and reload the current page.",
          "enabled": true,
          "order": 2,
          "availableWhenTrialLocked": false
        },
        {
          "id": "duplicate_tab",
          "title": "Duplicate Tab",
          "tooltip": "Create a copy of the current browser tab.",
          "enabled": true,
          "order": 3,
          "availableWhenTrialLocked": false
        },
        {
          "id": "refresh_all_tabs",
          "title": "Refresh All Tabs",
          "tooltip": "Reload all open browser tabs.",
          "enabled": true,
          "order": 4,
          "availableWhenTrialLocked": false
        },
        {
          "id": "screenshot",
          "title": "Screenshot",
          "tooltip": "Capture a screenshot of the current browser window.",
          "enabled": true,
          "order": 5,
          "availableWhenTrialLocked": true
        },
        {
          "id": "payment_card",
          "title": "Enter/Update Your Payment Card",
          "tooltip": "Manage the payment card associated with your account.",
          "enabled": true,
          "order": 6,
          "availableWhenTrialLocked": false
        },
        {
          "id": "buy_more_licenses",
          "title": "Buy More Licenses",
          "tooltip": "Purchase additional BrowserJet licenses.",
          "enabled": true,
          "order": 7,
          "availableWhenTrialLocked": false
        },
        {
          "id": "contact_us",
          "title": "Contact Us",
          "tooltip": "Get in touch with the BrowserJet support team.",
          "enabled": true,
          "order": 8,
          "availableWhenTrialLocked": true
        },
        {
          "id": "change_key",
          "title": "Change Your Key",
          "tooltip": "Replace your current BrowserJet license key.",
          "enabled": true,
          "order": 9,
          "availableWhenTrialLocked": true
        },
        {
          "id": "twitter",
          "title": "Connect Us",
          "tooltip": "Follow BrowserJet on X (Twitter) for updates.",
          "enabled": true,
          "order": 10,
          "availableWhenTrialLocked": true
        }
      ]
    }
    """
    
    static let `default` = MenuConfiguration(
        schemaVersion: 1,
        items: [
            MenuItemConfiguration(
                id: "new_tab",
                title: "New Tab",
                tooltip: "Open a new browser tab.",
                enabled: true,
                order: 1,
                availableWhenTrialLocked: false
            ),
            MenuItemConfiguration(
                id: "burn_ip_reload",
                title: "Burn IP and Reload",
                tooltip: "Switch to the next available IP and reload the current page.",
                enabled: true,
                order: 2,
                availableWhenTrialLocked: false
            ),
            MenuItemConfiguration(
                id: "duplicate_tab",
                title: "Duplicate Tab",
                tooltip: "Create a copy of the current browser tab.",
                enabled: true,
                order: 3,
                availableWhenTrialLocked: false
            ),
            MenuItemConfiguration(
                id: "refresh_all_tabs",
                title: "Refresh All Tabs",
                tooltip: "Reload all open browser tabs.",
                enabled: true,
                order: 4,
                availableWhenTrialLocked: false
            ),
            MenuItemConfiguration(
                id: "screenshot",
                title: "Screenshot",
                tooltip: "Capture a screenshot of the current browser window.",
                enabled: true,
                order: 5,
                availableWhenTrialLocked: true
            ),
            MenuItemConfiguration(
                id: "payment_card",
                title: "Enter/Update Your Payment Card",
                tooltip: "Manage the payment card associated with your account.",
                enabled: true,
                order: 6,
                availableWhenTrialLocked: false
            ),
            MenuItemConfiguration(
                id: "buy_more_licenses",
                title: "Buy More Licenses",
                tooltip: "Purchase additional BrowserJet licenses.",
                enabled: true,
                order: 7,
                availableWhenTrialLocked: false
            ),
            MenuItemConfiguration(
                id: "contact_us",
                title: "Contact Us",
                tooltip: "Get in touch with the BrowserJet support team.",
                enabled: true,
                order: 8,
                availableWhenTrialLocked: true
            ),
            MenuItemConfiguration(
                id: "change_key",
                title: "Change Your Key",
                tooltip: "Replace your current BrowserJet license key.",
                enabled: true,
                order: 9,
                availableWhenTrialLocked: true
            ),
            MenuItemConfiguration(
                id: "twitter",
                title: "Connect Us",
                tooltip: "Follow BrowserJet on X (Twitter) for updates.",
                enabled: true,
                order: 10,
                availableWhenTrialLocked: true
            )
        ]
    )
}
