//
//  CornerRadius.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 12/02/2026.
//

import SwiftUI

enum CornerRadius {
    case fixed(CGFloat)
    case capsule

    func apply(to view: some View) -> some View {
        switch self {
        case .fixed(let radius):
            return AnyView(view.cornerRadius(radius))
        case .capsule:
            return AnyView(view.clipShape(Capsule()))
        }
    }
}
