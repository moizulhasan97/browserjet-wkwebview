//
//  ImportExportCardView.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 08/07/2026.
//

import SwiftUI

/// Bulk management: two equal-width actions (default `.full` width on `BrowserJetAppButton`
/// splits evenly inside this `HStack`) plus a compact format hint underneath.
struct ImportExportCardView: View {
    @Environment(\.appTheme)
    private var theme
    @Environment(\.designSystem)
    private var designSystem

    @ObservedObject var viewModel: ManageMyProxyViewModel

    var body: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    BrowserJetAppButton(
                        title: viewModel.isImporting ? "Importing…" : "Import CSV / TXT",
                        icon: "square.and.arrow.up",
                        type: .secondaryLarge,
                        isDisabled: viewModel.isImporting || viewModel.selectedGroup == nil
                    ) {
                        viewModel.isImportPickerPresented = true
                    }

                    BrowserJetAppButton(
                        title: "Export CSV",
                        icon: "square.and.arrow.down",
                        type: .secondaryLarge,
                        isDisabled: viewModel.proxiesInSelectedGroup.isEmpty
                    ) {
                        viewModel.prepareExport()
                    }
                }

                Text(ManageMyProxyMessages.importFormatHint)
                    .font(designSystem.typography.textCaption.font)
                    .foregroundStyle(theme.textFieldSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
