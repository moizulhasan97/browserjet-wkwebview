//
//  EnvironmentBadgeView.swift
//  browserjet-wkwebview
//
//  Created by Moiz Ul Hasan on 22/01/2026.
//

import SwiftUI

struct EnvironmentBadgeView: View {
    let environment: AppEnvironment

    private var title: String { environment.displayName.uppercased() }

    private var backgroundColor: Color {
        switch environment {
        case .development: return .red.opacity(0.90)
        case .staging:     return .orange.opacity(0.90)
        case .production:  return .clear
        }
    }

    var body: some View {
        if environment != .production {
            Text(title)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(backgroundColor)
                .clipShape(Capsule())
                .shadow(radius: 3)
                .accessibilityLabel("Environment: \(environment.displayName)")
                .allowsHitTesting(false)
        }
    }
}
