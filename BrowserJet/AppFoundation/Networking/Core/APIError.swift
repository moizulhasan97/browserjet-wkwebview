//
//  APIError.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 24/02/2026.
//

import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case noData
    case unauthorized            // 401–500
    case serverError             // 501–599
    case duplicateEmail          // domain-specific
    case invalidResponse
    case underlying(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:       return "Invalid request URL."
        case .noData:           return "No data received."
        case .unauthorized:     return "Authentication failed."
        case .serverError:      return "Server error. Try again later."
        case .duplicateEmail:   return "This email is already registered."
        case .invalidResponse:  return "Unexpected server response."
        case .underlying(let error): return error.localizedDescription
        }
    }
}
