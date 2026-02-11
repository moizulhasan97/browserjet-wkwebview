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
                       Color(red: 0.74, green: 0.91, blue: 1.0),
                       Color(red: 0.47, green: 0.78, blue: 1.0),
                       Color(red: 0.12, green: 0.56, blue: 0.98)
                   ],
                   startPoint: .topLeading,
                   endPoint: .bottomTrailing
               )

           case .solid(let color):
               color
           }
       }
}
