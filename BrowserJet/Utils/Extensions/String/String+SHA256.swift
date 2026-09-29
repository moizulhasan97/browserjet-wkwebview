//
//  String+SHA256.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 05/07/2026.
//

import CryptoKit
import Foundation

extension String {
    /// Full 64-character lowercase hex SHA256 digest of this string's UTF-8 bytes.
    var sha256: String {
        let digest = SHA256.hash(data: Data(utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    /// SHA256 digest truncated to the first `length` hex characters. Stable and non-reversible —
    /// suitable for anonymized identifiers (e.g. crash-reporting user IDs). Never use where full
    /// cryptographic collision resistance is required.
    func sha256Prefix(_ length: Int) -> String {
        String(sha256.prefix(length))
    }
}
