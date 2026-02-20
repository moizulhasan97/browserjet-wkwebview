//
//  DuplicateTabsPopoverView.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 20/02/2026.
//


import SwiftUI

struct DuplicateTabsPopoverView: View {
    let maxCount: Int
    let onConfirm: (Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedCount: Int = 1

    var body: some View {
        VStack(spacing: 16) {
            Text("Duplicate Tabs")
                .font(.system(size: 14, weight: .semibold))

            Picker("Count", selection: $selectedCount) {
                ForEach(1...maxCount, id: \.self) { value in
                    Text("\(value)").tag(value)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 120)

            Button("OK") {
                onConfirm(selectedCount)
                dismiss()
            }
            .keyboardShortcut(.return)
            .buttonStyle(.borderedProminent)
        }
        .padding(20)
        .frame(width: 220)
    }
}