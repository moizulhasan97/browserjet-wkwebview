//
//  PremiumProxyPayloadDecryptor.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 27/03/2026.
//

import Foundation
import CommonCrypto

enum PremiumProxyDecryptError: Error {
    case notUTF8Ciphertext
    case aesKeyOrIVInvalid
    case decryptFailed
    case invalidJSON
    case emptyProxyList
}

private extension Data {
    func decryptAES(key: Data, iv: Data, options: Int = kCCOptionPKCS7Padding) -> Data? {
        guard !isEmpty else { return nil }
        return iv.withUnsafeBytes { ivBuf in
            key.withUnsafeBytes { keyBuf in
                self.withUnsafeBytes { dataInBuf in
                    let outSize = count + kCCBlockSizeAES128 * 2
                    let out = UnsafeMutableRawPointer.allocate(byteCount: outSize, alignment: 1)
                    defer { out.deallocate() }
                    var moved = 0
                    let status = CCCrypt(
                        CCOperation(kCCDecrypt),
                        CCAlgorithm(kCCAlgorithmAES),
                        CCOptions(options),
                        keyBuf.baseAddress,
                        key.count,
                        ivBuf.baseAddress,
                        dataInBuf.baseAddress,
                        count,
                        out,
                        outSize,
                        &moved
                    )
                    guard status == kCCSuccess else { return nil }
                    return Data(bytes: out, count: moved)
                }
            }
        }
    }
}

enum PremiumProxyPayloadDecryptor {

    private static let keyString = "support BrowserJ"
    private static let ivString = "BrowserJet_AESIV"

    static func decodePremiumProxies(from responseData: Data) throws -> [DecryptedPremiumProxy] {
        let data = stripUTF8BOM(responseData)

        if let rows = decodePlainJSONProxyList(from: data), !rows.isEmpty {
            return rows
        }

        let cipherText = try extractCiphertextString(from: data)
        let plainData = try decryptBase64Ciphertext(cipherText)

        if let rows = decodePlainJSONProxyList(from: plainData), !rows.isEmpty {
            return rows
        }
        throw PremiumProxyDecryptError.invalidJSON
    }

    private static func decodePlainJSONProxyList(from data: Data) -> [DecryptedPremiumProxy]? {
        if let rows = try? JSONDecoder().decode([DecryptedPremiumProxy].self, from: data), !rows.isEmpty {
            return rows
        }
        if let wrapped = try? JSONDecoder().decode(DecryptedPremiumProxies.self, from: data), !wrapped.premiumProxies.isEmpty {
            return wrapped.premiumProxies
        }
        return nil
    }

    // MARK: - Extract ciphertext (raw body or JSON envelope)

    private static func stripUTF8BOM(_ data: Data) -> Data {
        if data.starts(with: [0xEF, 0xBB, 0xBF]) {
            return Data(data.dropFirst(3))
        }
        return data
    }

    private static func extractCiphertextString(from data: Data) throws -> String {
        guard let raw = String(data: data, encoding: .utf8) else {
            throw PremiumProxyDecryptError.notUTF8Ciphertext
        }
        var trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.first == "\u{FEFF}" {
            trimmed.removeFirst()
        }

        if let obj = try? JSONSerialization.jsonObject(with: data) {
            if let s = obj as? String {
                return normalizeBase64Wrapper(s)
            }
            if let dict = obj as? [String: Any] {
                for (_, value) in dict {
                    if let s = value as? String, looksLikeBase64Payload(s) {
                        return normalizeBase64Wrapper(s)
                    }
                }
            }
            if let arr = obj as? [Any] {
                for item in arr {
                    if let s = item as? String, looksLikeBase64Payload(s) {
                        return normalizeBase64Wrapper(s)
                    }
                }
            }
        }

        return normalizeBase64Wrapper(trimmed)
    }

    private static func normalizeBase64Wrapper(_ s: String) -> String {
        var t = s.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.count >= 2, t.hasPrefix("\""), t.hasSuffix("\"") {
            t.removeFirst()
            t.removeLast()
            t = t.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return t
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\r", with: "")
    }

    private static func looksLikeBase64Payload(_ s: String) -> Bool {
        let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
        guard t.count >= 64 else { return false }
        let allowed = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=\n\r ")
        return t.unicodeScalars.allSatisfy { allowed.contains($0) }
    }

    // MARK: - AES
    private static func dataFromBase64Lossy(_ b64: String) -> Data? {
        if let d = Data(base64Encoded: b64, options: [.ignoreUnknownCharacters]) {
            return d
        }
        let segments = b64.split { $0.isWhitespace }.map(String.init).filter { !$0.isEmpty }
        return segments.max(by: { $0.count < $1.count }).flatMap {
            Data(base64Encoded: $0, options: [.ignoreUnknownCharacters])
        }
    }

    private static func decryptBase64Ciphertext(_ cipherText: String) throws -> Data {
        guard
            keyString.count == kCCKeySizeAES128,
            ivString.count == kCCBlockSizeAES128,
            let keyData = keyString.data(using: .utf8),
            let ivData = ivString.data(using: .utf8)
        else {
            throw PremiumProxyDecryptError.aesKeyOrIVInvalid
        }

        var b64 = cipherText
        if b64.contains("-") || b64.contains("_") {
            b64 = b64.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        }

        guard let cipherData = dataFromBase64Lossy(b64) else {
            throw PremiumProxyDecryptError.decryptFailed
        }
        guard let plain = cipherData.decryptAES(key: keyData, iv: ivData) else {
            throw PremiumProxyDecryptError.decryptFailed
        }
        if (try? JSONSerialization.jsonObject(with: plain)) == nil {
            throw PremiumProxyDecryptError.invalidJSON
        }
        return plain
    }
}
