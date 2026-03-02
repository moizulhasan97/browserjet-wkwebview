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
    static let forgotPasswordLink = "Forgot password?"

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
