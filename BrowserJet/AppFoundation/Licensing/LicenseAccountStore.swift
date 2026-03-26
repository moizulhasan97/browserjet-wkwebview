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

    private init(licenseStore: LicenseStore = LicenseStore()) {
        self.licenseStore = licenseStore
        refresh()
    }

    func refresh() {
        userKind = Self.userKind(from: licenseStore.load())
    }

    var isTrialUser: Bool { userKind == .trial }

    var isPaidUser: Bool { userKind == .paid }

    static func userKind(from license: PersistedLicense?) -> UserKind? {
        guard let raw = license?.userKind, !raw.isEmpty else { return nil }
        return UserKind(rawValue: raw)
    }
}
