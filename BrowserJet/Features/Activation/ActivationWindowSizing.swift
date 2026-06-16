//
//  ActivationWindowSizing.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 28/05/2026.
//

import AppKit
import SwiftUI

// MARK: - Metrics

enum ActivationWindowMetrics {
    /// Matches launcher width so activation and post-verify launcher align.
    static let contentWidth: CGFloat = 500

    /// Initial window height before the first content measurement (matches launcher).
    static let fullFormPlaceholderHeight: CGFloat = 639

    static let screenVerticalMargin: CGFloat = 48
    static let minContentHeight: CGFloat = 320

    static var placeholderContentSize: NSSize {
        NSSize(width: contentWidth, height: fullFormPlaceholderHeight)
    }

    static func clampedContentHeight(_ measured: CGFloat) -> CGFloat {
        let resolved = max(measured, minContentHeight)
        guard let screen = NSScreen.main else { return resolved }
        let maxHeight = screen.visibleFrame.height - screenVerticalMargin
        return min(resolved, max(120, maxHeight))
    }
}

// MARK: - Content measurement

struct ActivationMeasuredContentSizeKey: PreferenceKey {
    static var defaultValue: CGSize = .zero

    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        let next = nextValue()
        guard next.height > 0 else { return }
        if next.height > value.height {
            value = next
        }
    }
}

private struct ActivationContentSizeReporter: ViewModifier {
    func body(content: Content) -> some View {
        content.background {
            GeometryReader { proxy in
                Color.clear.preference(
                    key: ActivationMeasuredContentSizeKey.self,
                    value: proxy.size
                )
            }
        }
    }
}

extension View {
    /// Reports intrinsic size for dynamic activation window height (fixed width via caller).
    func reportActivationContentSize() -> some View {
        modifier(ActivationContentSizeReporter())
    }
}
