//
//  BrowserJetAppButton.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 12/02/2026.
//

import SwiftUI

struct BrowserJetAppButton: View {
    @Environment(\.appTheme) private var theme
    private let title: String
    private let type: BrowserJetButtonStyle.ButtonType
    private let width: CustomWidth
    private let height: CGFloat
    private let isDisabled: Bool
    private let action: () -> Void
    
    init(
        title: String,
        type: BrowserJetButtonStyle.ButtonType,
        width: CustomWidth = .full,
        height: CGFloat = 68.0,
        isDisabled: Bool,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.type = type
        self.width = width
        self.height = height
        self.isDisabled = isDisabled
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            //
            HStack(spacing: 8) {
                //
                Text(title)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(height: height)
            .contentShape(Rectangle())
        }
        .buttonStyle(
            BrowserJetButtonStyle(
                width: width,
                type: type,
                isDisabled: isDisabled
            )
        )
        .disabled(isDisabled)
    }
}


// MARK: - HuntingButtonStyle
struct BrowserJetButtonStyle: ButtonStyle {
    
    enum ButtonType: Equatable {
        case primaryLarge
    }
    
    @Environment(\.designSystem) private var designSystem
    
    let width: CustomWidth
    let type: ButtonType
    let isDisabled: Bool
    
    init(
        width: CustomWidth = .full,
        type: ButtonType,
        isDisabled: Bool
    ) {
        self.width = width
        self.type = type
        self.isDisabled = isDisabled
    }
    
    private func resolvedStyle() -> any BrowserJetButtonStyleProtocol {
        designSystem.buttonStyle.style(
            for: type,
            typography: designSystem.typography,
            viewConfig: designSystem.viewConfig
        )
    }
    
    func makeBody(configuration: Configuration) -> some View {
        let style = resolvedStyle()
        let isPressed = configuration.isPressed && !isDisabled
        
        let backgroundColor: Color =
        isDisabled ? style.backgroundDisabledColor :
        (isPressed ? style.backgroundHighlightedColor : style.backgroundColor)
        
        let titleColor: Color =
        isDisabled ? style.titleDisabledColor :
        (isPressed ? style.titleHighlightedColor : style.titleColor)
        
        let borderColor: Color =
        isDisabled ? style.borderDisabledColor :
        (isPressed ? style.borderHighlightedColor : style.borderColor)
        
        return configuration.label
            .font(style.font) // ✅ no more getCustomFont()
            .modifier(WidthModifier(width: width))
            .padding(style.contentInsets)
            .background(backgroundColor)
            .foregroundColor(titleColor)
            .overlay(
                Group {
                    switch style.cornerRadius {
                    case .fixed(let radius):
                        RoundedRectangle(cornerRadius: radius)
                            .stroke(borderColor, lineWidth: style.borderWidth)
                    case .capsule:
                        Capsule()
                            .stroke(borderColor, lineWidth: style.borderWidth)
                    }
                }
            )
            .modifier(CornerRadiusModifier(cornerRadius: style.cornerRadius))
            .opacity(isDisabled ? 0.6 : 1.0)
    }
}

// MARK: - WidthModifier
private struct WidthModifier: ViewModifier {
    let width: CustomWidth
    
    func body(content: Content) -> some View {
        switch width {
        case .full:
            content
                .frame(maxWidth: .infinity)
        case .fixed(let width):
            content
                .frame(width: CGFloat(width))
        case .padded(let width):
            content
                .padding(.horizontal, width)
        }
    }
}

