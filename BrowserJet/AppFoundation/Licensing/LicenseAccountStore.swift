//
//  LicenseAccountStore.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 26/03/2026.
//

import Foundation

@MainActor
final class LicenseAccountStore: ObservableObject {
    static let shared = LicenseAccountStore()

    private let licenseStore: LicenseStore

    @Published private(set) var userKind: UserKind?
    @Published private(set) var subscriptionTier: SubscriptionTier?
    /// Raw backend tier code (e.g. `lite`, empty). Exposed because plan resolution maps the raw code through
    /// Remote Config `plans_config.tierCodeMap`, so new backend codes can be mapped without a release.
    @Published private(set) var tierRawValue: String = ""
    @Published private(set) var username: String = "User"

    private init(licenseStore: LicenseStore = LicenseStore()) {
        self.licenseStore = licenseStore
        refresh()
    }

    func refresh() {
        let license = licenseStore.load()
        userKind = Self.userKind(from: license)
        subscriptionTier = Self.subscriptionTier(from: license)
        tierRawValue = license?.tierRawValue ?? ""
        username = Self.displayUsername(from: license)
    }

    var isTrialUser: Bool { userKind == .trial }
    var isPaidUser: Bool { userKind == .paid }

    static func userKind(from license: PersistedLicense?) -> UserKind? {
        guard let raw = license?.userKind, !raw.isEmpty else { return nil }
        return UserKind(rawValue: raw)
    }

    static func subscriptionTier(from license: PersistedLicense?) -> SubscriptionTier? {
        guard let raw = license?.subscriptionTier, !raw.isEmpty else { return nil }
        return SubscriptionTier(rawValue: raw) ?? .unknown
    }

    static func displayUsername(from license: PersistedLicense?) -> String {
        let trimmed = license?.username.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? "User" : trimmed
    }
}
