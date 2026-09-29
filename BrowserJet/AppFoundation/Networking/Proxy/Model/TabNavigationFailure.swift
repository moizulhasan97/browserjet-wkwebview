//
//  TabNavigationFailure.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 24/09/2026.
//

import CFNetwork
import Foundation

/// A main-frame navigation that failed before WebKit committed any content.
///
/// Pure value type: classification lives here — not in the delegate or the view —
/// so it can be unit tested without a `WKWebView`.
struct TabNavigationFailure: Equatable {
    enum Kind: Equatable {
        case offline
        case connectionLost
        case timedOut
        case hostNotFound
        case cannotConnect
        case proxyUnavailable
        case insecureConnection
        case invalidAddress
        case tooManyRedirects
        case unknown
    }

    let kind: Kind
    /// The destination the user tried to reach. Retry loads this, and the
    /// address bar shows it while the error page is on screen.
    let failingURL: URL?
    let domain: String
    let code: Int

    var displayHost: String? {
        failingURL?.host
    }

    /// Stable, support-friendly identifier, e.g. `NSURLErrorDomain -1005`.
    var diagnosticCode: String {
        "\(domain) \(code)"
    }
}

// MARK: - Classification
extension TabNavigationFailure {
    /// Returns `nil` for failures that must never surface UI: user or programmatic
    /// cancellation, a navigation superseded by a newer one, or a load handed off
    /// by policy (downloads, new-tab routing).
    init?(error: Error, fallbackURL: URL?) {
        let nsError = error as NSError
        guard !Self.isSilent(nsError) else { return nil }

        self.init(
            kind: Self.kind(for: nsError),
            failingURL: Self.failingURL(from: nsError) ?? fallbackURL,
            domain: nsError.domain,
            code: nsError.code
        )
    }
}

private extension TabNavigationFailure {
    /// Legacy `WebKitErrorDomain` codes that `WKError` does not expose.
    enum WebKitLegacyError {
        static let domain = "WebKitErrorDomain"
        static let cannotShowURL = 101
        static let frameLoadInterruptedByPolicyChange = 102
        static let plugInWillHandleLoad = 204
    }

    static let proxyFailureCodes: Set<Int> = [
        Int(CFNetworkErrors.cfErrorHTTPProxyConnectionFailure.rawValue),
        Int(CFNetworkErrors.cfErrorHTTPBadProxyCredentials.rawValue),
        Int(CFNetworkErrors.cfErrorHTTPSProxyConnectionFailure.rawValue),
        Int(CFNetworkErrors.cfStreamErrorHTTPSProxyFailureUnexpectedResponseToCONNECTMethod.rawValue)
    ]

    static func isSilent(_ error: NSError) -> Bool {
        switch (error.domain, error.code) {
        case (NSURLErrorDomain, NSURLErrorCancelled),
            (WebKitLegacyError.domain, WebKitLegacyError.frameLoadInterruptedByPolicyChange),
            (WebKitLegacyError.domain, WebKitLegacyError.plugInWillHandleLoad):
            return true
        default:
            return false
        }
    }

    static func kind(for error: NSError) -> Kind {
        if isProxyFailure(error) {
            return .proxyUnavailable
        }

        switch error.domain {
        case NSURLErrorDomain:
            return urlErrorKind(for: error.code)
        case WebKitLegacyError.domain where error.code == WebKitLegacyError.cannotShowURL:
            return .invalidAddress
        default:
            return .unknown
        }
    }

    static func urlErrorKind(for code: Int) -> Kind {
        switch code {
        case NSURLErrorNotConnectedToInternet, NSURLErrorDataNotAllowed:
            return .offline
        case NSURLErrorNetworkConnectionLost:
            return .connectionLost
        case NSURLErrorTimedOut:
            return .timedOut
        case NSURLErrorCannotFindHost, NSURLErrorDNSLookupFailed:
            return .hostNotFound
        case NSURLErrorCannotConnectToHost:
            return .cannotConnect
        case NSURLErrorSecureConnectionFailed,
            NSURLErrorServerCertificateHasBadDate,
            NSURLErrorServerCertificateUntrusted,
            NSURLErrorServerCertificateHasUnknownRoot,
            NSURLErrorServerCertificateNotYetValid,
            NSURLErrorClientCertificateRejected,
            NSURLErrorClientCertificateRequired,
            NSURLErrorAppTransportSecurityRequiresSecureConnection:
            return .insecureConnection
        case NSURLErrorBadURL, NSURLErrorUnsupportedURL:
            return .invalidAddress
        case NSURLErrorHTTPTooManyRedirects:
            return .tooManyRedirects
        default:
            return .unknown
        }
    }

    /// Proxy failures can arrive top-level or wrapped inside an `NSURLErrorDomain` error.
    static func isProxyFailure(_ error: NSError) -> Bool {
        let cfNetworkDomain = kCFErrorDomainCFNetwork as String
        let underlying = error.userInfo[NSUnderlyingErrorKey] as? NSError
        return [error, underlying]
            .compactMap { $0 }
            .contains { $0.domain == cfNetworkDomain && proxyFailureCodes.contains($0.code) }
    }

    static func failingURL(from error: NSError) -> URL? {
        if let url = error.userInfo[NSURLErrorFailingURLErrorKey] as? URL {
            return url
        }
        guard let urlString = error.userInfo[NSURLErrorFailingURLStringErrorKey] as? String else {
            return nil
        }
        return URL(string: urlString)
    }
}
