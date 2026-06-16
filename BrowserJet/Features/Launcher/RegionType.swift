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
    // swiftlint:disable:next identifier_name
    case it = "IT"
    // swiftlint:disable:next identifier_name
    case nz = "NZ"
    // swiftlint:disable:next identifier_name
    case au = "AU"
    case uae = "UAE"
    // swiftlint:disable:next identifier_name
    case nl = "NL"
}

extension RegionType {
    var datatudeRegionSlug: String {
        switch self {
        case .uk: return "gb"
        case .us: return "us"
        case .ca: return "ca"
        case .it: return "it"
        case .nz: return "nz"
        case .au: return "au"
        case .uae: return "ae"
        case .nl: return "nl"
        }
    }
}
