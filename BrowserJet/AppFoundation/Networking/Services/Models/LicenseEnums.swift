//
//  LicenseEnums.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 24/02/2026.
//

enum AuthenticationType: String {
    case verified    = "verified"
    case notVerified = "notverified"
}

enum UserKind: String {
    case paid
    case trial
}

enum UserStatus: String {
    case active
    case rejected
}

enum SubscriptionTier: String, Codable {
    case basic
    case pro
    case unknown

    static func fromBackend(rawValue: String, userKind: UserKind) -> SubscriptionTier {
        let normalized = rawValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch normalized {
        case "lite":
            return .basic

        case "":
            // empty means Pro for paid users.
            return userKind == .paid ? .pro : .unknown

        default:
            // Includes 5Tab and any unknown future value.
            return .unknown
        }
    }
}

// Plan marketing names ("Captain - Lite" / "Captain - Pro") moved to `PlansConfig` (Remote Config `plans_config`),
// resolved through `PlanResolver`, so About and entitlements can never disagree.
