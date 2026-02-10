//
//  AppTheme.swift
//  browserjet-wkwebview
//
//  Created by Moiz Ul Hasan on 22/01/2026.
//

import SwiftUI

/// Minimal token surface (start small; expand as designs demand)
protocol AppTheme {
    // Surfaces
    var surfaceElevated: Color { get }

    // Text
    var textPrimary: Color { get }
    var textSecondary: Color { get }

    // Borders
    var border: Color { get }

    // Actions
    var accent: Color { get }
    var destructive: Color { get }

    // Status
    var badgeBackground: Color { get }
    var badgeText: Color { get }
}
