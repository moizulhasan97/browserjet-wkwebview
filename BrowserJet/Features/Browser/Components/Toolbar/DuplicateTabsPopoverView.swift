//
//  DuplicateTabsPopoverView.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 20/02/2026.
//

import SwiftUI

// struct DuplicateTabsPopoverView: View {
//    let maxCount: Int
//    let onConfirm: (Int) -> Void
//
//    @Environment(\.dismiss) private var dismiss
//    @State private var selectedCount: Int = 1
//
//    var body: some View {
//        VStack(spacing: 16) {
//            Text("Duplicate Tabs")
//                .font(.system(size: 14, weight: .semibold))
//
//            Picker("Count", selection: $selectedCount) {
//                ForEach(1...maxCount, id: \.self) { value in
//                    Text("\(value)").tag(value)
//                }
//            }
//            .pickerStyle(.menu)
//            .frame(width: 120)
//
//            Button("OK") {
//                onConfirm(selectedCount)
//                dismiss()
//            }
//            .keyboardShortcut(.return)
//            .buttonStyle(.borderedProminent)
//        }
//        .padding(20)
//        .frame(width: 220)
//    }
// }

struct DuplicateTabsPopoverView: View {
    @Environment(\.appTheme)
    private var theme

    @State private var selectedCount: Int
    /// Highest duplicate count offered. Comes from the window's plan limit (it used to be the app-wide
    /// `AppConfiguration.duplicateTabCounts`, 1...20), so Pro can duplicate up to its larger limit.
    let maxCount: Int
    let onConfirm: (Int) -> Void

    private var counts: [Int] {
        Array(1...maxCount)
    }

    init(maxCount: Int, onConfirm: @escaping (Int) -> Void) {
        let safeMax = max(1, maxCount)
        self.maxCount = safeMax
        self.onConfirm = onConfirm
        // Default of 2 kept from before, clamped so the picker's selection is always one of its options.
        _selectedCount = State(initialValue: min(2, safeMax))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Duplicate tabs")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(theme.textPrimary)

            Picker("Count", selection: $selectedCount) {
                ForEach(counts, id: \.self) { count in
                    Text("\(count)").tag(count)
                }
            }
            .pickerStyle(.menu)

            HStack {
                Spacer()
                Button("OK") { onConfirm(selectedCount) }
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(14)
        .frame(width: 220)
        .background(theme.surfaceCard)
    }
}
