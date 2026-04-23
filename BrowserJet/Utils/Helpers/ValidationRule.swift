//
//  ValidationRule.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 24/02/2026.
//

import Foundation

// MARK: - Validation State

enum RegexValidationState: Equatable {
    /// No rule configured — validation indicator is not shown.
    case none
    /// Text is empty — rule not yet evaluated.
    case empty
    /// Text matches the rule's pattern.
    case valid
    /// Text does not match the rule's pattern.
    case invalid
}

// MARK: - ValidationRule

struct ValidationRule {
    let pattern: String
    let defaultMessage: String
    private let expression: NSRegularExpression?

    init(_ pattern: String, defaultMessage: String = "") {
        self.pattern = pattern
        self.defaultMessage = defaultMessage
        self.expression = try? NSRegularExpression(pattern: pattern)
    }

    func evaluate(_ text: String) -> RegexValidationState {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .empty }
        guard let expression else { return .none }
        let range = NSRange(trimmed.startIndex..., in: trimmed)
        return expression.firstMatch(in: trimmed, range: range) != nil ? .valid : .invalid
    }

    /// Returns a copy of this rule with a different failure message.
    func message(_ override: String) -> ValidationRule {
        ValidationRule(pattern, defaultMessage: override)
    }
}

// MARK: - Built-in Rules

extension ValidationRule {

    /// `XXXX-XXXX-XXXX` where X is an uppercase letter or digit.
    static let licenseKey = ValidationRule(
        #"^[A-Z0-9]{24}$"#,
        defaultMessage: "Must be 24 uppercase letters and numbers"
    )

    /// Standard email address.
    static let email = ValidationRule(
        #"^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$"#,
        defaultMessage: "Enter a valid email address"
    )
    
    /// TODO: Confirm with Ebad bhai to match website regex.
    static let password = ValidationRule(
        #"^(?=.*[A-Za-z])(?=.*\d).{7,}$"#,
        defaultMessage: "At least 8 characters, including a letter and a number"
    )
}
