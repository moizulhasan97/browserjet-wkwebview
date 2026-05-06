//
//  URLConstants.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 06/05/2026.
//

import Foundation

@MainActor
enum URLConstants {
    private static var rc: RemoteConfigManager { .shared }
    
    static var baseServerURL: URL? {
        URL(string: rc.baseServerURL)
    }
    
    static var baseURL: URL? {
        URL(string: rc.baseWebURL)
    }
    
    static var contactUsURL: URL? {
        guard let base = baseURL else { return nil }
        return base.appendingPathComponent(rc.contactUsPath.trimmingCharacters(in: CharacterSet(charactersIn: "/")))
    }
    
    static var twitterURL: URL? {
        URL(string: rc.twitterURL)
    }
    
    static func updateYourCardURL(email: String?) -> URL? {
        makeServerURL(path: rc.updateCardPath, email: email)
    }
    
    static func buyMoreLicensesURL(email: String?) -> URL? {
        makeServerURL(path: rc.buyMoreLicensesPath, email: email)
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
        var components = URLComponents(url: base.appendingPathComponent(path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))), resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "Email", value: (email ?? "").trimmingCharacters(in: .whitespacesAndNewlines))
        ]
        return components?.url
    }
}
