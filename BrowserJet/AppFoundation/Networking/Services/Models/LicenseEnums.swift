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

extension SubscriptionTier {
    /// UI label for Customer Plans ("Captain - Lite" / "Captain - Pro").
    var captainPlanMarketingLine: String {
        switch self {
        case .pro: return "Captain - Pro"
        default: return "Captain - Lite"
        }
    }

    /// `.unknown` maps to Pro only for paid users; otherwise Lite
    func captainPlanMarketingLine(resolvingUnknownUserKind kind: UserKind) -> String {
        switch self {
        case .basic, .pro:
            return captainPlanMarketingLine
        case .unknown:
            return kind == .paid ? SubscriptionTier.pro.captainPlanMarketingLine
            : SubscriptionTier.basic.captainPlanMarketingLine
        }
    }
}
