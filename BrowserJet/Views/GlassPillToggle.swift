//
//  GlassPillToggle.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 11/02/2026.
//

import SwiftUI

struct GlassPillToggle: View {
    @Binding var isOn: Bool
    var isDisabled: Bool = false
    let outerCircleColor: Color = .C_6_C_6_C_6

    var body: some View {
        Capsule(style: .continuous)
            .fill(backgroundColor)
            .overlay(
                Capsule(style: .continuous)
                    .stroke(strokeColor, lineWidth: 1)
            )
            .frame(width: 56, height: 28)
            .overlay(alignment: isOn ? .trailing : .leading) {
                Circle()
                    .fill(circleColor)
                    .shadow(color: shadowColor, radius: 2, x: 0, y: 1)
                    .padding(3)
                    .frame(width: 28, height: 28)
            }
            .animation(.easeInOut(duration: 0.18), value: isOn)
            .animation(.easeInOut(duration: 0.18), value: isDisabled)
            .opacity(isDisabled ? 0.5 : 1.0)  // Reduce opacity when disabled
            .onTapGesture {
                if !isDisabled {
                    isOn.toggle()
                }
            }
    }

    // Computed properties for colors based on state
    private var backgroundColor: Color {
        if isDisabled {
            return outerCircleColor.opacity(0.1)  // Very light when disabled
        }
        return isOn ? ._0088_FF : outerCircleColor.opacity(0.2)
    }

    private var strokeColor: Color {
        if isDisabled {
            return Color.black.opacity(0.09)  // Lighter stroke when disabled
        }
        return Color.black.opacity(0.06)
    }

    private var circleColor: Color {
        if isDisabled {
            return Color.white.opacity(0.7)  // More transparent when disabled
        }
        return Color.white
    }

    private var shadowColor: Color {
        if isDisabled {
            return Color.black.opacity(0.06)  // Lighter shadow when disabled
        }
        return Color.black.opacity(0.12)
    }
}

#Preview {
    VStack(spacing: 20) {
        GlassPillToggle(isOn: .constant(false))
        GlassPillToggle(isOn: .constant(true))
        GlassPillToggle(
            isOn: .constant(false),
            isDisabled: true
        )
    }
    .padding()
    .background(Color(nsColor: .windowBackgroundColor))
}
