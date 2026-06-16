//
//  FontProvider.swift
//  browserjet-wkwebview
//
//  Created by Moiz Ul Hasan on 10/02/2026.
//

import SwiftUI

enum FontProvider {
    enum Weight {
        case ultraLight   // 100
        case thin         // 200
        case light        // 300
        case regular      // 400
        case medium       // 500
        case semiBold     // 600
        case bold         // 700
        case heavy        // 800
        case black        // 900

        var swiftWeight: Font.Weight {
            switch self {
            case .ultraLight: return .ultraLight
            case .thin:       return .thin
            case .light:      return .light
            case .regular:    return .regular
            case .medium:     return .medium
            case .semiBold:   return .semibold
            case .bold:       return .bold
            case .heavy:      return .heavy
            case .black:      return .black
            }
        }
    }

    case sfPro(weight: Weight)

    func font(size: CGFloat) -> Font {
        switch self {
        case .sfPro(let weight):
            return .system(size: size, weight: weight.swiftWeight, design: .default)
        }
    }
}
