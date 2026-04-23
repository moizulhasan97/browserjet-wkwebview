//
//  ActivationMessages.swift
//  BrowserJet
//
//

import Foundation

// MARK: - Rename this
enum ActivationMessages {
    
    // MARK: - Common
    
    static let okButtonTitle = "OK"
    
    // MARK: - Screen header
    
    static let welcomeTitle = "Welcome to Browser Jet"
    static let activateSubtitle = "Activate your license to continue"
    
    // MARK: - Form labels & placeholders
    
    static let enterYourKeyTitle = "Enter Your Key"
    static let licenseKeyPlaceholder = "XXXXXXXXXXXX"
    static let emailAddressTitle = "Email Address"
    static let emailPlaceholder = "you@example.com"
    static let emailValidationMessage = "Enter a valid email"
    static let passwordTitle = "Password"
    static let passwordPlaceholder = "Enter password"
    static let recoverAccountLink = "Click to Recover Account"
    
    // MARK: - Account recovery (forgot credentials)
    
    enum AccountRecovery {
        static let headline = "Enter your email to recover your account"
        static let body = """
We’ll send you login credentials to access your dashboard where you can view your license key.
"""
        static let continueButton = "Continue"
        /// Dismisses the recover sheet (form or success).
        static let dismissSheet = "Close"
        
        enum Success {
            static let title = "Check your email"
            static let message = """
We’ve sent your login details.
Open the dashboard to view your license key.
"""
            static let openDashboard = "Open Dashboard"
        }
    }
    
    /// Progress while verifying a license key already saved on this device.
    static let verifyingStoredKeyProgress = "Verifying saved license key…"
    
    /// Brief bootstrap state before a specific outcome is shown.
    static let bootstrapLoadingProgress = "Loading…"
    
    // MARK: - Mode (segmented + submit button)
    
    enum Mode {
        static let useKey = "Use Key"
        static let register = "Register"
        static let verifyButton = "Verify"
        static let createKeyButton = "Create Key"
    }
    
    // MARK: - Alerts
    
    /// Key verified successfully (before navigating to launcher).
    enum VerificationSuccess {
        static let title = "Success"
        static let message = "Your key has been verified successfully."
    }
    
    /// License shifted to this device (after Shift PC flow).
    enum ShiftSuccess {
        static let title = "Success"
        static let message = "Your license has been shifted to this device."
    }
    
    /// Trial expired alert.
    enum TrialExpired {
        static let title = "Trial Expired"
        static let message = "Your trial has expired. You will be redirected to the payment page."
    }
    
    /// License expired alert.
    enum LicenseExpired {
        static let title = "License Expired"
        static let message = "Your license has expired. You will be redirected to the payment page."
    }
}
