//
//  DesignSystem+Environment.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 11/02/2026.
//

import SwiftUI

private struct DesignSystemKey: EnvironmentKey {
    static let defaultValue: DesignSystem = .init()
}

extension EnvironmentValues {
    var designSystem: DesignSystem {
        get { self[DesignSystemKey.self] }
        set { self[DesignSystemKey.self] = newValue }
    }
}
