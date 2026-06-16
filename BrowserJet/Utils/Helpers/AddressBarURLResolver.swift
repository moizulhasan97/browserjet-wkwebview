//
//  AddressBarURLResolver.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 19/05/2026.
//

import Foundation

/// Resolves launcher / address-bar text into a navigable URL.
/// Matches the behavior of submitting the browser address field.
enum AddressBarURLResolver {
    static func resolve(_ input: String) -> URL? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if trimmed == "about:blank" {
            return URL(string: "about:blank")
        }

        if trimmed.contains("://"), let url = URL(string: trimmed) {
            return url
        }

        if trimmed.contains(".") && !trimmed.contains(" "),
            let url = URL(string: "https://\(trimmed)") {
            return url
        }

        let encodedQuery = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? trimmed
        return URL(string: "https://www.google.com/search?q=\(encodedQuery)")
    }
}
