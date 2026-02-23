//
//  BrowserJetTextfieldStyleProtocol.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 23/02/2026.
//

import SwiftUI

protocol BrowserJetTextFieldStyleProtocol {
    // Background
    var backgroundColor: Color { get }
    var backgroundDisabledColor: Color { get }
    var backgroundHighlightedColor: Color { get }

    // Text
    var textColor: Color { get }
    var textDisabledColor: Color { get }
    var textHighlightedColor: Color { get }

    // Placeholder
    var placeholderColor: Color { get }

    // Border
    var borderColor: Color { get }
    var borderDisabledColor: Color { get }
    var borderHighlightedColor: Color { get }
    var borderWidth: CGFloat { get }

    // Layout
    var contentInsets: EdgeInsets { get }
    var cornerRadius: CornerRadius { get }
    var font: Font { get }

    // Optional height (handy to standardize)
    var height: CGFloat { get }
}

// Defaults
extension BrowserJetTextFieldStyleProtocol {
    var contentInsets: EdgeInsets { .init(top: 0, leading: 0, bottom: 0, trailing: 0) }
    var borderWidth: CGFloat { 1 }
}
