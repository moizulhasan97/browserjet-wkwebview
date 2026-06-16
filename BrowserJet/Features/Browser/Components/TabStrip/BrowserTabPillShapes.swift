//
//  BrowserTabPillShapes.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 16/02/2026.
//

import SwiftUI

// Type eraser for Shape protocol to allow conditional shape returns
struct AnyShape: Shape {
    private let _path: (CGRect) -> Path

    init<S: Shape>(_ shape: S) {
        _path = shape.path(in:)
    }

    func path(in rect: CGRect) -> Path {
        _path(rect)
    }
}

// Custom shape for selected tab: rounded top corners and slightly rounded bottom corners
struct SelectedTabShape: Shape {
    var topCornerRadius: CGFloat
    var bottomCornerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let topRadius = min(topCornerRadius, rect.width / 2, rect.height / 2)
        let bottomRadius = min(bottomCornerRadius, rect.width / 2, rect.height / 2)

        // Start from left side, just below top-left corner
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + topRadius))

        // Top-left rounded corner
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + topRadius, y: rect.minY),
            control: CGPoint(x: rect.minX, y: rect.minY)
        )

        // Top edge
        path.addLine(to: CGPoint(x: rect.maxX - topRadius, y: rect.minY))

        // Top-right rounded corner
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + topRadius),
            control: CGPoint(x: rect.maxX, y: rect.minY)
        )

        // Right edge (straight down to bottom-right corner)
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - bottomRadius))

        // Bottom-right rounded corner (for blend effect)
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - bottomRadius, y: rect.maxY),
            control: CGPoint(x: rect.maxX, y: rect.maxY)
        )

        // Bottom edge
        path.addLine(to: CGPoint(x: rect.minX + bottomRadius, y: rect.maxY))

        // Bottom-left rounded corner (for blend effect)
        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.maxY - bottomRadius),
            control: CGPoint(x: rect.minX, y: rect.maxY)
        )

        // Left edge (closes the path)
        path.closeSubpath()
        return path
    }
}

// Border shape for selected tab: only top and sides, no bottom
struct SelectedTabBorderShape: Shape {
    var topCornerRadius: CGFloat
    var bottomCornerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let topRadius = min(topCornerRadius, rect.width / 2, rect.height / 2)
        let bottomRadius = min(bottomCornerRadius, rect.width / 2, rect.height / 2)
        let lineWidth: CGFloat = 0.5

        // Start from left side, just below top-left corner
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + topRadius))

        // Top-left rounded corner
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + topRadius, y: rect.minY),
            control: CGPoint(x: rect.minX, y: rect.minY)
        )

        // Top edge
        path.addLine(to: CGPoint(x: rect.maxX - topRadius, y: rect.minY))

        // Top-right rounded corner
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + topRadius),
            control: CGPoint(x: rect.maxX, y: rect.minY)
        )

        // Right edge (straight down, but stop before bottom to avoid bottom border)
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - bottomRadius - lineWidth))

        // Left edge (straight up from bottom, connecting back to start)
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - bottomRadius - lineWidth))

        return path
    }
}
