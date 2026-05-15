//
//  RegionType.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 12/02/2026.
//

enum RegionType: String, CaseIterable, Hashable {
    // swiftlint:disable:next identifier_name
    case uk = "UK"
    // swiftlint:disable:next identifier_name
    case us = "US"
    // swiftlint:disable:next identifier_name
    case ca = "CA"
}

extension RegionType {
    /// For vpn2
    var datatudeRegionSlug: String {
        switch self {
        case .uk: return "gb"
        case .us: return "us"
        case .ca: return "ca"
        }
    }
}
