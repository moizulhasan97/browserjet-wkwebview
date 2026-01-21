//
//  AppLogger.swift
//  browserjet-wkwebview
//
//  Created by Moiz Ul Hasan on 21/01/2026.
//

import Foundation
import os.log

enum LogLevel: Int, Comparable {
    case debug = 0
    case info
    case warning
    case error

    static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var emoji: String {
        switch self {
        case .debug:   return "🐞"
        case .info:    return "ℹ️"
        case .warning: return "⚠️"
        case .error:   return "❌"
        }
    }

    var osLogType: OSLogType {
        switch self {
        case .debug:   return .debug
        case .info:    return .info
        case .warning: return .default
        case .error:   return .error
        }
    }
}

enum AppLogger {

    // MARK: - Configuration

    private static var minimumLogLevel: LogLevel {
        switch AppEnvironment.current {
        case .development:
            return .debug
        case .staging:
            return .info
        case .production:
            return .error
        }
    }

    private static let subsystem = Bundle.main.bundleIdentifier ?? "BrowserJet"
    private static let logger = Logger(subsystem: subsystem, category: "App")

    // MARK: - Public API

    static func debug(_ message: @autoclosure () -> String,
                      file: String = #fileID,
                      line: Int = #line) {
        log(.debug, message(), file: file, line: line)
    }

    static func info(_ message: @autoclosure () -> String,
                     file: String = #fileID,
                     line: Int = #line) {
        log(.info, message(), file: file, line: line)
    }

    static func warning(_ message: @autoclosure () -> String,
                        file: String = #fileID,
                        line: Int = #line) {
        log(.warning, message(), file: file, line: line)
    }

    static func error(_ message: @autoclosure () -> String,
                      file: String = #fileID,
                      line: Int = #line) {
        log(.error, message(), file: file, line: line)
    }

    // MARK: - Core logger

    private static func log(_ level: LogLevel,
                            _ message: String,
                            file: String,
                            line: Int) {
        guard level >= minimumLogLevel else { return }

        let composed = "\(level.emoji) [\(file):\(line)] \(message)"

        logger.log(level: level.osLogType, "\(composed)")
    }
}
