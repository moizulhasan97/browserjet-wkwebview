//
//  DesignMetrics.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 11/02/2026.
//

import SwiftUI

// TODO: - Make it screen-oriented
enum DesignMetrics {
    // MARK: - Corner Radius
    static let screenCornerRadius: CGFloat = 28
    static let cardCornerRadius: CGFloat = 22
    static let controlCornerRadius: CGFloat = 14
    static let buttonCornerRadius: CGFloat = 30

    // MARK: - Spacing / Padding
    static let screenPadding: CGFloat = 28
    static let cardPadding: CGFloat = 20
    static let sectionSpacing: CGFloat = 18
    static let rowSpacing: CGFloat = 14

    // MARK: - Stroke
    static let cardStrokeWidth: CGFloat = 1
    static let controlStrokeWidth: CGFloat = 1

    // MARK: - Shadows
    static let cardShadowRadius: CGFloat = 30
    static let cardShadowY: CGFloat = 8

    // MARK: - Control sizing
    static let launcherAddressFieldHeight: CGFloat = 42 // launcher search bar
    static let browserAddressFieldHeight: CGFloat = 34 // launcher search bar
    static let buttonHeight: CGFloat = 64

    /// Canonical height for `BrowserJetAppButton` across the app.
    /// Sized for desktop input — wide enough to read as a prominent CTA,
    /// short enough to feel native to macOS rather than iOS-touch.
    static let primaryButtonHeight: CGFloat = 38
}
