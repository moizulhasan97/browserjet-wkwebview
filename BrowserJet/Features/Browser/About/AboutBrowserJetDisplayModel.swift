//
//  AboutBrowserJetDisplayModel.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 07/05/2026.
//

import Foundation

enum AboutBrowserJetLicensePresentationStatus: Equatable {
    case active
    case trialActive
    case expired
    
    var badgeTitle: String {
        switch self {
        case .active: return "Active"
        case .trialActive: return "Trial Active"
        case .expired: return "Expired"
        }
    }
    
    var expiryRowTitle: String {
        switch self {
        case .active: return "Expires"
        case .trialActive: return "Trial Ends"
        case .expired: return "Expired"
        }
    }
}

struct AboutBrowserJetDisplayModel: Equatable {
    let username: String
    let email: String
    let planDisplayName: String
    let licenseKey: String
    let licensesPurchased: Int
    let expiryDisplayText: String
    let appVersion: String
    let buildNumber: String
    let presentationStatus: AboutBrowserJetLicensePresentationStatus
    
    var displayVersionLine: String {
        "Version \(appVersion) (\(buildNumber))"
    }
}

enum AboutBrowserJetContentBuilder {
    
    static func canPresent(license: PersistedLicense?) -> Bool {
        guard let license else { return false }
        guard let auth = AuthenticationType(rawValue: license.authenticationType), auth == .verified else {
            return false
        }
        guard let status = UserStatus(rawValue: license.userStatus), status == .active else {
            return false
        }
        return true
    }
    
    @MainActor
    static func buildModel(
        license: PersistedLicense,
        licenseKeyFromStore: String,
        referenceNow: Date = Date(),
        bundle: Bundle = .main
    ) -> AboutBrowserJetDisplayModel {
        let kind = UserKind(rawValue: license.userKind) ?? .trial
        
        let planBase = captainPlanBaseName(license: license, kind: kind)
        let planDisplayName = kind == .trial ? "\(planBase) (Trial)" : planBase
        
        let presentationStatus = presentationStatus(license: license, kind: kind, referenceNow: referenceNow)
        let expiryText = expiryDisplayString(license: license, kind: kind)
        
        let displayUsername = LicenseAccountStore.displayUsername(from: license)
        let email = license.userEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return AboutBrowserJetDisplayModel(
            username: displayUsername,
            email: email,
            planDisplayName: planDisplayName,
            licenseKey: licenseKeyFromStore.trimmingCharacters(in: .whitespacesAndNewlines),
            licensesPurchased: license.numberOfLicenses,
            expiryDisplayText: expiryText,
            appVersion: bundle.appVersion,
            buildNumber: bundle.buildNumber,
            presentationStatus: presentationStatus
        )
    }
    
    private static func captainPlanBaseName(license: PersistedLicense, kind: UserKind) -> String {
        let tierRaw = license.tierRawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let tierRawLower = tierRaw.lowercased()

        if kind == .trial && license.trialExpired {
            /// We give trials only for Lite
            return SubscriptionTier.basic.captainPlanMarketingLine
        }

        if tierRawLower == "lite" {
            return SubscriptionTier.basic.captainPlanMarketingLine
        }

        if tierRaw.isEmpty && kind == .paid {
            return SubscriptionTier.pro.captainPlanMarketingLine
        }

        let tierEnum = SubscriptionTier(rawValue: license.subscriptionTier) ?? .unknown
        return tierEnum.captainPlanMarketingLine(resolvingUnknownUserKind: kind)
    }
    
    private static func presentationStatus(
        license: PersistedLicense,
        kind: UserKind,
        referenceNow: Date
    ) -> AboutBrowserJetLicensePresentationStatus {
        switch kind {
        case .paid:
            return referenceNow > license.userExpiryDate ? .expired : .active
        case .trial:
            if isTrialExpired(license: license, referenceNow: referenceNow) { return .expired }
            return .trialActive
        }
    }
    
    private static func isTrialExpired(license: PersistedLicense, referenceNow: Date) -> Bool {
        if license.trialExpired { return true }
        if let proxyExpiry = license.proxyExpiryDate {
            return referenceNow > proxyExpiry
        }
        return false
    }
    
    private static func expiryDisplayString(license: PersistedLicense, kind: UserKind) -> String {
        switch kind {
        case .paid:
            return AboutDateFormatting.mediumDateTime.string(from: license.userExpiryDate)
        case .trial:
            if let proxyExpiry = license.proxyExpiryDate {
                return AboutDateFormatting.mediumDateTime.string(from: proxyExpiry)
            }
            return "—"
        }
    }
}

private enum AboutDateFormatting {
    static let mediumDateTime: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = .current
        return f
    }()
}
