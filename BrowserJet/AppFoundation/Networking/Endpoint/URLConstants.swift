//
//  URLConstants.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 06/05/2026.
//

import Foundation

@MainActor
enum URLConstants {
    private static var remoteConfig: RemoteConfigManager { .shared }

    static var baseServerURL: URL? {
        URL(string: remoteConfig.baseServerURL)
    }

    static var baseURL: URL? {
        URL(string: remoteConfig.baseWebURL)
    }

    static var contactUsURL: URL? {
        guard let base = baseURL else { return nil }
        let trimmedPath = remoteConfig.contactUsPath.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return base.appendingPathComponent(trimmedPath)
    }

    static var twitterURL: URL? {
        URL(string: remoteConfig.twitterURL)
    }

    static func updateYourCardURL(email: String?) -> URL? {
        makeServerURL(path: remoteConfig.updateCardPath, email: email)
    }

    static func buyMoreLicensesURL(email: String?) -> URL? {
        makeServerURL(path: remoteConfig.buyMoreLicensesPath, email: email)
    }

    static func renewalPaymentURL(email: String?) -> URL? {
        guard let base = baseServerURL else { return nil }
        var components = URLComponents(url: base.appendingPathComponent("License.ashx"), resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "Method", value: "PayRenewal"),
            URLQueryItem(name: "Email", value: (email ?? "").trimmingCharacters(in: .whitespacesAndNewlines))
        ]
        return components?.url
    }

    private static func makeServerURL(path: String, email: String?) -> URL? {
        guard let base = baseServerURL else { return nil }
        let trimmedPath = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        var components = URLComponents(
            url: base.appendingPathComponent(trimmedPath),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [
            URLQueryItem(name: "Email", value: (email ?? "").trimmingCharacters(in: .whitespacesAndNewlines))
        ]
        return components?.url
    }
}
