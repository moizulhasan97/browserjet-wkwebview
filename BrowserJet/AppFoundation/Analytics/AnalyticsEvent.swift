//
//  AnalyticsEvent.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 05/07/2026.
//

import Foundation


enum AnalyticsEvent {
    // MARK: - Activation / License
    case trialSignupAttempted
    case trialSignupSucceeded
    case trialSignupFailed(reason: String)
    case licenseVerifyAttempted
    case licenseVerifySucceeded(outcome: String)
    case licenseVerifyFailed(reason: String)
    case forgotPasswordTapped
    case shiftLicenseTapped
    case recoverAccountSubmitted(succeeded: Bool)
    case changeKeySubmitted(succeeded: Bool)

    // MARK: - Launcher
    case vpnToggled(enabled: Bool)
    case premiumProxyToggled(enabled: Bool)
    case browserLaunched(connectionCategory: String, tabCount: Int, isolationMode: String)

    // MARK: - Browser session
    case tabOpened
    case tabClosed
    case tabDuplicated(count: Int)
    case tabReopened
    case proxyBurned

    // MARK: - Settings
    /// `changedFields` holds field *names* only (e.g. "default_url"), never their values.
    case settingsSaved(changedFields: [String])

    // MARK: - Updates
    case updateCheckCompleted(succeeded: Bool)
    case updateFound(version: String)
    case updateInstalled
}

extension AnalyticsEvent {
    var name: String {
        switch self {
        case .trialSignupAttempted: return "trial_signup_attempted"
        case .trialSignupSucceeded: return "trial_signup_succeeded"
        case .trialSignupFailed: return "trial_signup_failed"
        case .licenseVerifyAttempted: return "license_verify_attempted"
        case .licenseVerifySucceeded: return "license_verify_succeeded"
        case .licenseVerifyFailed: return "license_verify_failed"
        case .forgotPasswordTapped: return "forgot_password_tapped"
        case .shiftLicenseTapped: return "shift_license_tapped"
        case .recoverAccountSubmitted: return "recover_account_submitted"
        case .changeKeySubmitted: return "change_key_submitted"
        case .vpnToggled: return "vpn_toggled"
        case .premiumProxyToggled: return "premium_proxy_toggled"
        case .browserLaunched: return "browser_launched"
        case .tabOpened: return "tab_opened"
        case .tabClosed: return "tab_closed"
        case .tabDuplicated: return "tab_duplicated"
        case .tabReopened: return "tab_reopened"
        case .proxyBurned: return "proxy_burned"
        case .settingsSaved: return "settings_saved"
        case .updateCheckCompleted: return "update_check_completed"
        case .updateFound: return "update_found"
        case .updateInstalled: return "update_installed"
        }
    }

    var parameters: [String: Any]? {
        switch self {
        case .trialSignupFailed(let reason), .licenseVerifyFailed(let reason):
            return ["reason": reason]
        case .licenseVerifySucceeded(let outcome):
            return ["outcome": outcome]
        case .recoverAccountSubmitted(let succeeded), .changeKeySubmitted(let succeeded):
            return ["succeeded": succeeded]
        case .vpnToggled(let enabled), .premiumProxyToggled(let enabled):
            return ["enabled": enabled]
        case .browserLaunched(let connectionCategory, let tabCount, let isolationMode):
            return [
                "connection_category": connectionCategory,
                "tab_count": tabCount,
                "isolation_mode": isolationMode
            ]
        case .tabDuplicated(let count):
            return ["count": count]
        case .settingsSaved(let changedFields):
            return ["changed_fields": changedFields.joined(separator: ",")]
        case .updateCheckCompleted(let succeeded):
            return ["succeeded": succeeded]
        case .updateFound(let version):
            return ["version": version]
        default:
            return nil
        }
    }
}
