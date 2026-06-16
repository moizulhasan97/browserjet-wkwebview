//
//  BrowserJetButtonStyleProtocol.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 11/02/2026.
//

import SwiftUI

protocol BrowserJetButtonStyleProtocol {
    var backgroundColor: Color { get }
    var backgroundDisabledColor: Color { get }
    var backgroundHighlightedColor: Color { get }

    var titleColor: Color { get }
    var titleDisabledColor: Color { get }
    var titleHighlightedColor: Color { get }

    var borderColor: Color { get }
    var borderDisabledColor: Color { get }
    var borderHighlightedColor: Color { get }
    var borderWidth: CGFloat { get }

    var contentInsets: EdgeInsets { get }
    var cornerRadius: CornerRadius { get }
    var font: Font { get }

    var shouldUnderline: Bool { get }
}

extension BrowserJetButtonStyleProtocol {
    var contentInsets: EdgeInsets {
        .init(top: 0, leading: 0, bottom: 0, trailing: 0)
    }

    var shouldUnderline: Bool {
        false
    }
}
