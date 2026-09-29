//
//  NavigationErrorMessages.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 24/09/2026.
//

import Foundation

enum NavigationErrorMessages {
    static let retryButtonTitle = "Try Again"
    static let retryingButtonTitle = "Loading…"
    static let unknownHost = "this site"

    enum Title {
        static let offline = "You're not connected to the internet"
        static let connectionLost = "The network connection was lost"
        static let timedOut = "This site took too long to respond"
        static let unreachable = "This site can't be reached"
        static let proxyUnavailable = "Couldn't connect through the proxy"
        static let insecureConnection = "A secure connection can't be established"
        static let invalidAddress = "This web address isn't valid"
        static let tooManyRedirects = "This page isn't working"
        static let unknown = "This page couldn't be loaded"
    }

    enum Message {
        static let offline = "Check your Wi-Fi or network cable, then try again."
        static let invalidAddress = "The address may be mistyped, or it uses a format BrowserJet can't open."

        static func connectionLost(host: String) -> String {
            "The connection to \(host) was interrupted while the page was loading."
        }

        static func timedOut(host: String) -> String {
            "\(host) didn't respond in time."
        }

        static func hostNotFound(host: String) -> String {
            "The server address for \(host) couldn't be found."
        }

        static func cannotConnect(host: String) -> String {
            "\(host) refused the connection."
        }

        static func proxyUnavailable(host: String) -> String {
            "BrowserJet couldn't reach \(host) through the current proxy."
        }

        static func insecureConnection(host: String) -> String {
            "BrowserJet couldn't verify a secure connection to \(host)."
        }

        static func tooManyRedirects(host: String) -> String {
            "\(host) redirected you too many times."
        }

        static func unknown(host: String) -> String {
            "Something went wrong while loading \(host)."
        }
    }

    enum Suggestion {
        static let checkConnection = "Check your internet connection, then try again."
        static let burnIP = "You're browsing through a proxy. If this keeps happening, try Burn IP and Reload."
        static let checkDateAndTime = "Make sure your Mac's date and time are correct, or try again later."
    }
}
