//
//  AppLogger.swift
//  browserjet-wkwebview
//
//  Created by Moiz Ul Hasan on 10/02/2026.
//

import Foundation
import os.log

enum AppEnvironment: String {
    case development
    case production
    
    static var current: AppEnvironment {
#if DEBUG
        return .development
#else
        return .production
#endif
    }
    
    var displayName: String {
        switch self {
        case .development: return "Development"
        case .production:  return "Production"
        }
    }
    
    static var currentConfiguration: AppConfiguration {
        switch current {
        case .development:
            return .development
        case .production:
            return .production
        }
    }
}

enum AppLogger {
    // MARK: - Configuration
    
    private static var minimumLogLevel: LogLevel {
        switch AppEnvironment.current {
        case .development:
            return .debug
        case .production:
            return .error
        }
    }
    
    private static let subsystem = Bundle.main.bundleIdentifier ?? "BrowserJet"
    private static let logger = Logger(subsystem: subsystem, category: "App")
    
    // MARK: - Public API
    
    static func debug(
        _ message: @autoclosure () -> String,
        file: String = #fileID,
        line: Int = #line
    ) {
        log(.debug, message(), file: file, line: line)
    }
    
    static func info(
        _ message: @autoclosure () -> String,
        file: String = #fileID,
        line: Int = #line
    ) {
        log(.info, message(), file: file, line: line)
    }
    
    static func warning(
        _ message: @autoclosure () -> String,
        file: String = #fileID,
        line: Int = #line
    ) {
        log(.warning, message(), file: file, line: line)
    }
    
    static func error(
        _ message: @autoclosure () -> String,
        file: String = #fileID,
        line: Int = #line
    ) {
        log(.error, message(), file: file, line: line)
    }
    
    // MARK: - Core logger
    private static func log(
        _ level: LogLevel,
        _ message: String,
        file: String,
        line: Int
    ) {
        guard level >= minimumLogLevel else { return }
        
        let composed = "\(level.emoji) [\(file):\(line)] \(message)"
        
        logger.log(level: level.osLogType, "\(composed)")
    }
}
