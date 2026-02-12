//
//  CornerRadiusModifier.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 12/02/2026.
//

import SwiftUI

struct CornerRadiusModifier: ViewModifier {
    let cornerRadius: CornerRadius
    
    func body(content: Content) -> some View {
        switch cornerRadius {
        case .fixed(let radius):
            content.cornerRadius(radius)
        case .capsule:
            content.clipShape(Capsule())
        }
    }
}
