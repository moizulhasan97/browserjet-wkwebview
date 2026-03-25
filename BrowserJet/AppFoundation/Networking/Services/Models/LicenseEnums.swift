//
//  LicenseEnums.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 24/02/2026.
//

enum AuthenticationType: String {
    case verified    = "verified"
    case notVerified = "notverified"
}

enum UserKind: String {
    case paid  = "paid"
    case trial = "trial"
}

enum UserStatus: String {
    case active   = "active"
    case rejected = "rejected"
}
