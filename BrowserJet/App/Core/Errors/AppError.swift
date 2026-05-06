//
//  AppError.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 25/02/2026.
//

import Foundation

enum AppGraceShutdown {
    
    static let alertTitle = "BrowserJet"
    
    enum Format {
        /// `%d` — minute count until termination after the user dismisses the alert.
        static let keyExpiredQuitMinutes =
        "Your key has expired. Please save your work as BrowserJet will close in %d minutes."
        
        /// `%d` — second count until termination after the user dismisses the alert.
        static let keyExpiredQuitSeconds =
        "Your key has expired. Please save your work as BrowserJet will close in %d seconds."
        
        /// `%d` — seconds until quit after the user dismisses the alert (MAC / other machine).
        static let macMismatchQuitSeconds =
        "Your key is being used on another computer. This BrowserJet instance will quit in %d seconds."
    }
    
    /// Nanosecond delays — use for `Task.sleep` so messaging stays aligned with actual wait.
    enum Timing {
        static let verifyKeyPollInterval: UInt64 = 10.seconds
        static let checkExpiryPollInterval: UInt64 = 10.seconds //30.minutes
        static let macMismatchQuit: UInt64 = 10.seconds
        static let keyExpiredQuit: UInt64 = 10.minutes
    }
    
    /// Message matching `delay`: uses **minutes** when delay ≥ 1 minute, otherwise **seconds**.
    static func keyExpiredQuitMessage(forDelayNanoseconds delay: UInt64) -> String {
        let oneMinute: UInt64 = 60_000_000_000
        if delay >= oneMinute {
            let minutes = max(1, Int(delay / oneMinute))
            return String(format: Format.keyExpiredQuitMinutes, minutes)
        }
        let seconds = max(1, Int(delay / 1_000_000_000))
        return String(format: Format.keyExpiredQuitSeconds, seconds)
    }
    
    static func macMismatchQuitMessage() -> String {
        let seconds = max(1, Int(Timing.macMismatchQuit / 1_000_000_000))
        return String(format: Format.macMismatchQuitSeconds, seconds)
    }
}

enum AppError: Error, LocalizedError {
    // MARK: - Validation
    case invalidInput
    case duplicateEmail
    case parametersNil
    
    // MARK: - Auth / License
    case notVerified
    case licenseExpired
    
    // MARK: - Network
    case authenticationError
    case badRequest
    case outdated
    case failed
    case noData
    case missingURL
    
    // MARK: - Parsing / Encoding
    case unableToParse
    case unableToDecode
    case encodingFailed
    
    // MARK: - File / Storage
    case unableToSaveFile
    
    // MARK: - Generic
    case somethingWrong
    case unknownError
    
    // MARK: - Custom message
    case custom(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidInput:
            return "Invalid input. Please try again."
        case .duplicateEmail:
            return "All licenses are registered against this email and password. Please enter key or try forgot or contact support."
        case .parametersNil:
            return "Parameters were nil."
            
        case .notVerified:
            return "Key not verified. Please try again."
        case .licenseExpired:
            return "All licences have expired. Please renew your purchase."
            
        case .authenticationError:
            return "You need to be authenticated first."
        case .badRequest:
            return "Bad request."
        case .outdated:
            return "The url you requested is outdated."
        case .failed:
            return "Network request failed."
        case .noData:
            return "Response returned with no data to decode."
        case .missingURL:
            return "URL is nil."
            
        case .unableToParse:
            return "Unable to parse. Try again."
        case .unableToDecode:
            return "We could not decode the response."
        case .encodingFailed:
            return "Parameters encoding failed."
            
        case .unableToSaveFile:
            return "Unable to save file. Please try again."
            
        case .somethingWrong:
            return "Something went wrong. Please try again later."
        case .unknownError:
            return "Unknown error occurred. Please try again later."
            
        case .custom(let message):
            return message
        }
    }
}
