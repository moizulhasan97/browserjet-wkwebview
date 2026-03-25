//
//  DateFormatterProvider.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 24/02/2026.
//

import Foundation

enum DateFormatterProvider {

    /// "yyyy-MM-dd HH:mm:ss" — matches the server's completeDateAndTime format.
    static let serverDateTime: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0)
        return f
    }()

    /// "yyyy-MM-dd" — date only, no time component.
    static let serverDate: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0)
        return f
    }()

    /// "MM/dd/yyyy h:mm:ss a" — e.g. "10/23/2026 11:00:45 AM"
    static let slashDateTime12Hour: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MM/dd/yyyy h:mm:ss a"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0)
        return f
    }()

    /// "dd MMM yyyy" — human-readable display format, e.g. "24 Feb 2026".
    static let displayDate: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd MMM yyyy"
        f.locale = Locale.current
        return f
    }()

    /// Attempts to parse a date string by trying each formatter in order.
    static func date(from string: String) -> Date? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        let formatters: [DateFormatter] = [
            serverDateTime,
            serverDate,
            slashDateTime12Hour
        ]

        for formatter in formatters {
            if let date = formatter.date(from: trimmed) {
                return date
            }
        }

        AppLogger.warning("DateFormatterProvider: could not parse date string '\(trimmed)'")
        return nil
    }
}
