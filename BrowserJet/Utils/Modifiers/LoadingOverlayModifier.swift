//
//  LoadingOverlayModifier.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 24/02/2026.
//

import SwiftUI

struct LoadingOverlayModifier: ViewModifier {
    let isLoading: Bool
    let message: String?

    func body(content: Content) -> some View {
        ZStack {
            content
                .allowsHitTesting(!isLoading)  // disables the underlying view while loading

            if isLoading {
                LoadingOverlayView(message: message)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isLoading)
    }
}

extension View {
    func loadingOverlay(
        isLoading: Bool,
        message: String? = nil
    ) -> some View {
        modifier(LoadingOverlayModifier(isLoading: isLoading, message: message))
    }
}
