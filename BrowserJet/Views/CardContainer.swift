//
//  CardContainer.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 11/02/2026.
//

import SwiftUI

struct CardContainer<Content: View>: View {
    @Environment(\.appTheme)
    private var theme
    private let padding: CGFloat
    private let content: Content

    init(
        padding: CGFloat = DesignMetrics.cardPadding,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(theme.surfaceCard)
            .overlay(
                RoundedRectangle(
                    cornerRadius: DesignMetrics.cardCornerRadius,
                    style: .continuous
                )
                .stroke(
                    theme.strokeCard,
                    lineWidth: DesignMetrics.cardStrokeWidth
                )
            )
            .clipShape(RoundedRectangle(
                cornerRadius: DesignMetrics.cardCornerRadius,
                style: .continuous
            ))
            .shadow(
                color: .black.opacity(0.12),
                radius: DesignMetrics.cardShadowRadius,
                x: 0,
                y: DesignMetrics.cardShadowY
            )
    }
}

#Preview {
    CardContainer {
        VStack {
            Text("Hello world")
                .foregroundStyle(.orange)

            Text("Hello world")
                .foregroundStyle(.black)
        }
    }
}
