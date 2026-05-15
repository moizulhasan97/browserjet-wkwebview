//
//  AppTheme.swift
//  browserjet-wkwebview
//
//  Created by Moiz Ul Hasan on 22/01/2026.
//

import SwiftUI

protocol AppTheme {
    // MARK: - Surfaces (Glass)
    var surfaceCard: Color { get }
    var surfaceCardOverlay: Color { get }
    var surfaceControl: Color { get }
    var surfaceControlOverlay: Color { get }

    // MARK: - Text
    var textPrimary: Color { get }
    // TextFields
    var textFieldSecondary: Color { get }
    // Connection
    var vpnConnection: Color { get }

    // MARK: - Strokes / Dividers
    var strokeCard: Color { get }
    var strokeControl: Color { get }
    var divider: Color { get }

    // MARK: - Actions
    var accent: Color { get }
    var accentPressed: Color { get }
    var accentDisabled: Color { get }

    // MARK: - Badge
    var badgeBackground: Color { get }
    var badgeText: Color { get }

    // MARK: - Error
    var danger: Color { get }
}
