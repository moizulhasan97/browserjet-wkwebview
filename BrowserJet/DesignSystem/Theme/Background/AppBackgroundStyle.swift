//
//  AppBackgroundStyle.swift
//  browserjet-wkwebview
//
//  Created by Moiz Ul Hasan on 10/02/2026.
//

import SwiftUI

enum AppBackgroundStyle {
    case browserJetGradient
    case solid(Color)
}

extension AppBackgroundStyle {
    @ViewBuilder
    func makeView() -> some View {
        switch self {
        case .browserJetGradient:
            LinearGradient(
                colors: [
                    Color(red: 0.92, green: 0.96, blue: 1.00),
                    Color(red: 0.84, green: 0.92, blue: 1.00),
                    Color(red: 0.76, green: 0.88, blue: 1.00)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

        case .solid(let color):
            color
        }
    }
}
