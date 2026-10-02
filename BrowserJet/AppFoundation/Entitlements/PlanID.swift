//
//  PlanID.swift
//  BrowserJet
//

import Foundation

/// Identifier of a subscription plan (`basic`, `pro`, `trial`, …).
///
/// Why a string-backed struct instead of an enum: Remote Config (`plans_config`) can introduce a new plan
/// (e.g. `enterprise`) and map a backend tier code to it without an app release. The static members are only
/// the plans this build ships in-app defaults for.
struct PlanID: RawRepresentable, Hashable, Sendable {
    static let basic = PlanID(rawValue: "basic")
    static let pro = PlanID(rawValue: "pro")
    static let trial = PlanID(rawValue: "trial")

    let rawValue: String

    /// Normalised so `"Pro"`, `" pro "` and `"pro"` typed in the Firebase console all resolve to the same plan.
    init(rawValue: String) {
        self.rawValue = rawValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}

extension PlanID: Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.init(rawValue: try container.decode(String.self))
    }
}
