//
//  EndpointsConfig.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 05/07/2026.
//

import Foundation

struct EndpointsConfig: Decodable {
    static let supportedSchemaVersion = 1

    let schemaVersion: Int
    let baseWebURL: String
    let baseServerURL: String
    let serverPaths: ServerPaths
    let webPaths: WebPaths
    let externalLinks: ExternalLinks

    var isSupported: Bool {
        schemaVersion <= Self.supportedSchemaVersion
    }

    init(
        schemaVersion: Int = 1,
        baseWebURL: String,
        baseServerURL: String,
        serverPaths: ServerPaths,
        webPaths: WebPaths,
        externalLinks: ExternalLinks
    ) {
        self.schemaVersion = schemaVersion
        self.baseWebURL = baseWebURL
        self.baseServerURL = baseServerURL
        self.serverPaths = serverPaths
        self.webPaths = webPaths
        self.externalLinks = externalLinks
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 1
        baseWebURL = try container.decodeIfPresent(String.self, forKey: .baseWebURL)
            ?? "https://browserjet.com"
        baseServerURL = try container.decodeIfPresent(String.self, forKey: .baseServerURL)
            ?? "https://service.browserjet.com"
        serverPaths = try container.decodeIfPresent(ServerPaths.self, forKey: .serverPaths)
            ?? .default
        webPaths = try container.decodeIfPresent(WebPaths.self, forKey: .webPaths)
            ?? .default
        externalLinks = try container.decodeIfPresent(ExternalLinks.self, forKey: .externalLinks)
            ?? .default
    }

    private enum CodingKeys: String, CodingKey {
        case schemaVersion, baseWebURL, baseServerURL, serverPaths, webPaths, externalLinks
    }

    struct ServerPaths: Decodable {
        let updateCard: String
        let buyMoreLicenses: String
        let browserPurchase: String

        init(updateCard: String, buyMoreLicenses: String, browserPurchase: String) {
            self.updateCard = updateCard
            self.buyMoreLicenses = buyMoreLicenses
            self.browserPurchase = browserPurchase
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            updateCard = try container.decodeIfPresent(String.self, forKey: .updateCard)
                ?? "/UpdateCard.aspx"
            buyMoreLicenses = try container.decodeIfPresent(String.self, forKey: .buyMoreLicenses)
                ?? "/MoreLicenses.aspx"
            browserPurchase = try container.decodeIfPresent(String.self, forKey: .browserPurchase)
                ?? "/BrowserPurchase.aspx"
        }

        private enum CodingKeys: String, CodingKey {
            case updateCard, buyMoreLicenses, browserPurchase
        }

        static let `default` = ServerPaths(
            updateCard: "/UpdateCard.aspx",
            buyMoreLicenses: "/MoreLicenses.aspx",
            browserPurchase: "/BrowserPurchase.aspx"
        )
    }

    struct WebPaths: Decodable {
        let contactUs: String

        init(contactUs: String) {
            self.contactUs = contactUs
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            contactUs = try container.decodeIfPresent(String.self, forKey: .contactUs) ?? "/contact"
        }

        private enum CodingKeys: String, CodingKey {
            case contactUs
        }

        static let `default` = WebPaths(contactUs: "/contact")
    }

    struct ExternalLinks: Decodable {
        let twitter: String

        init(twitter: String) {
            self.twitter = twitter
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            twitter = try container.decodeIfPresent(String.self, forKey: .twitter) ?? "https://twitter.com/browserjet"
        }

        private enum CodingKeys: String, CodingKey {
            case twitter
        }

        static let `default` = ExternalLinks(twitter: "https://twitter.com/browserjet")
    }
}

extension EndpointsConfig {
    static let defaultJSONString = """
    {
      "schemaVersion": 1,
      "baseWebURL": "https://browserjet.com",
      "baseServerURL": "https://service.browserjet.com",
      "serverPaths": {
        "updateCard": "/UpdateCard.aspx",
        "buyMoreLicenses": "/MoreLicenses.aspx",
        "browserPurchase": "/BrowserPurchase.aspx"
      },
      "webPaths": {
        "contactUs": "/contact"
      },
      "externalLinks": {
        "twitter": "https://twitter.com/browserjet"
      }
    }
    """

    /// In-memory fallback when Firebase is unreachable or decode fails.
    static let `default` = EndpointsConfig(
        schemaVersion: 1,
        baseWebURL: "https://browserjet.com",
        baseServerURL: "https://service.browserjet.com",
        serverPaths: .default,
        webPaths: .default,
        externalLinks: .default
    )
}
