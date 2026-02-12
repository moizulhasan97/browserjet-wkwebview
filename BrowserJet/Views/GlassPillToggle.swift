//
//  GlassPillToggle.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 11/02/2026.
//

import SwiftUI

struct GlassPillToggle: View {
    @Binding var isOn: Bool
    
    var body: some View {
        Capsule(style: .continuous)
            .fill(Color.white.opacity(0.85))
            .overlay(
                Capsule(style: .continuous)
                    .stroke(Color.black.opacity(0.06), lineWidth: 1)
            )
            .frame(width: 56, height: 28)
            .overlay(alignment: isOn ? .trailing : .leading) {
                Circle()
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.12), radius: 2, x: 0, y: 1)
                    .padding(3)
                    .frame(width: 28, height: 28)
            }
            .animation(.easeInOut(duration: 0.18), value: isOn)
            .onTapGesture {
                isOn.toggle()
            }
    }
}

#Preview {
    VStack(spacing: 20) {
        GlassPillToggle(isOn: .constant(false))
        GlassPillToggle(isOn: .constant(true))
        
    }
    .padding()
    .background(Color(nsColor: .windowBackgroundColor))
}
