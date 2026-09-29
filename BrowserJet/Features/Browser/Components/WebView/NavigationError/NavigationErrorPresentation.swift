//
//  NavigationErrorPresentation.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 24/09/2026.
//

import Foundation

/// View-ready content for a `TabNavigationFailure`.
///
/// Kept separate from `NavigationErrorView` so copy and iconography can be
/// unit tested and changed without touching layout.
struct NavigationErrorPresentation: Equatable {
    let symbolName: String
    let title: String
    let message: String
    let suggestion: String?
    let diagnosticCode: String

    init(failure: TabNavigationFailure, isProxied: Bool) {
        let host = failure.displayHost ?? NavigationErrorMessages.unknownHost
        self.symbolName = Self.symbolName(for: failure.kind)
        self.title = Self.title(for: failure.kind)
        self.message = Self.message(for: failure.kind, host: host)
        self.suggestion = Self.suggestion(for: failure.kind, isProxied: isProxied)
        self.diagnosticCode = failure.diagnosticCode
    }
}

private extension NavigationErrorPresentation {
    typealias Kind = TabNavigationFailure.Kind

    static func symbolName(for kind: Kind) -> String {
        switch kind {
        case .offline:
            return "wifi.slash"
        case .connectionLost, .timedOut, .hostNotFound, .cannotConnect:
            return "network.slash"
        case .proxyUnavailable:
            return "shield.slash"
        case .insecureConnection:
            return "lock.slash"
        case .invalidAddress, .tooManyRedirects, .unknown:
            return "exclamationmark.triangle"
        }
    }

    static func title(for kind: Kind) -> String {
        typealias Title = NavigationErrorMessages.Title
        switch kind {
        case .offline: return Title.offline
        case .connectionLost: return Title.connectionLost
        case .timedOut: return Title.timedOut
        case .hostNotFound, .cannotConnect: return Title.unreachable
        case .proxyUnavailable: return Title.proxyUnavailable
        case .insecureConnection: return Title.insecureConnection
        case .invalidAddress: return Title.invalidAddress
        case .tooManyRedirects: return Title.tooManyRedirects
        case .unknown: return Title.unknown
        }
    }

    static func message(for kind: Kind, host: String) -> String {
        typealias Message = NavigationErrorMessages.Message
        switch kind {
        case .offline: return Message.offline
        case .connectionLost: return Message.connectionLost(host: host)
        case .timedOut: return Message.timedOut(host: host)
        case .hostNotFound: return Message.hostNotFound(host: host)
        case .cannotConnect: return Message.cannotConnect(host: host)
        case .proxyUnavailable: return Message.proxyUnavailable(host: host)
        case .insecureConnection: return Message.insecureConnection(host: host)
        case .invalidAddress: return Message.invalidAddress
        case .tooManyRedirects: return Message.tooManyRedirects(host: host)
        case .unknown: return Message.unknown(host: host)
        }
    }

    static func suggestion(for kind: Kind, isProxied: Bool) -> String? {
        typealias Suggestion = NavigationErrorMessages.Suggestion
        switch kind {
        case .connectionLost, .timedOut, .hostNotFound, .cannotConnect, .proxyUnavailable:
            return isProxied ? Suggestion.burnIP : Suggestion.checkConnection
        case .insecureConnection:
            return Suggestion.checkDateAndTime
        case .offline, .invalidAddress, .tooManyRedirects, .unknown:
            return nil
        }
    }
}
