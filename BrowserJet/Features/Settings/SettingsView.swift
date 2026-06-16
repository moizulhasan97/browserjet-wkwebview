//
//  SettingsView.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 16/05/2026.
//

import SwiftUI

// MARK: - App Settings scene root

struct SettingsRootView: View {
    @Environment(\.colorScheme)
    private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager

    private var resolvedColorScheme: ColorScheme {
        themeManager.resolvedColorScheme(for: colorScheme)
    }

    var body: some View {
        SettingsView(themeManager: themeManager)
            .browserJetThemedRoot(themeManager: themeManager, colorScheme: resolvedColorScheme)
            .frame(minWidth: 520, minHeight: 400)
    }
}

// MARK: - Settings content

struct SettingsView: View {
    @Environment(\.appTheme)
    private var theme
    @Environment(\.designSystem)
    private var designSystem

    @StateObject private var viewModel: SettingsViewModel

    init(themeManager: ThemeManager) {
        _viewModel = StateObject(wrappedValue: SettingsViewModel(themeManager: themeManager))
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignMetrics.sectionSpacing) {
                    generalSection
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            if viewModel.hasUnsavedChanges {
                Divider()
                    .overlay(theme.divider)
                footer
            }
        }
        .onChange(of: viewModel.draftMode) { _, newMode in
            viewModel.syncAppearancePreview(to: newMode)
        }
    }

    private var generalSection: some View {
        VStack(alignment: .leading, spacing: DesignMetrics.rowSpacing) {
            Text("General")
                .font(designSystem.typography.heading4.font)
                .foregroundStyle(theme.textPrimary)

            CardContainer {
                VStack(alignment: .leading, spacing: DesignMetrics.sectionSpacing) {
                    appearanceRow
                    Divider().overlay(theme.divider)
                    defaultURLSection
                    Divider().overlay(theme.divider)
                    confirmBeforeQuitRow
                }
            }
        }
    }

    private var appearanceRow: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Appearance")
                .font(designSystem.typography.textBody1.font)
                .foregroundStyle(theme.textPrimary)

            Picker("", selection: $viewModel.draftMode) {
                Text("System").tag(ThemeManager.Mode.system)
                Text("Light").tag(ThemeManager.Mode.light)
                Text("Dark").tag(ThemeManager.Mode.dark)
            }
            .pickerStyle(.radioGroup)
            .labelsHidden()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var defaultURLSection: some View {
        VStack(alignment: .leading, spacing: DesignMetrics.rowSpacing) {
            openBlankPageRow

            BrowserJetTextField(
                type: .launcherAddress,
                title: "Default URL",
                text: $viewModel.draftDefaultURL,
                placeholder: LauncherStartURLPreferences.blankPageURL
            )
            .disabled(viewModel.isDefaultURLFieldDisabled)
            .opacity(viewModel.isDefaultURLFieldDisabled ? 0.55 : 1)

            if viewModel.isDefaultURLFieldDisabled {
                Text(
                    """
                    Launcher will start with \(LauncherStartURLPreferences.blankPageURL). \
                    You can still change the address on the launcher.
                    """
                )
                    .font(designSystem.typography.textCaption.font)
                    .foregroundStyle(theme.textFieldSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var openBlankPageRow: some View {
        HStack {
            Text("Open blank page")
                .font(designSystem.typography.textBody1.font)
                .foregroundStyle(theme.textPrimary)
            Spacer()
            GlassPillToggle(
                isOn: Binding(
                    get: { viewModel.draftOpenBlankPage },
                    set: { viewModel.setDraftOpenBlankPage($0) }
                )
            )
        }
    }

    private var confirmBeforeQuitRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Confirm before quitting")
                    .font(designSystem.typography.textBody1.font)
                    .foregroundStyle(theme.textPrimary)
                Spacer()
                GlassPillToggle(
                    isOn: Binding(
                        get: { viewModel.draftConfirmBeforeQuit },
                        set: { viewModel.setDraftConfirmBeforeQuit($0) }
                    )
                )
            }
            Text(
                """
                When enabled, BrowserJet asks for confirmation before quitting \
                (⌘Q, closing the last tab, or closing the last window).
                """
            )
                .font(designSystem.typography.textCaption.font)
                .foregroundStyle(theme.textFieldSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var footer: some View {
        HStack(spacing: 12) {
            Spacer()

            BrowserJetAppButton(
                title: "Cancel",
                type: .secondaryLarge,
                width: .fixed(width: 100),
                isDisabled: false
            ) {
                viewModel.cancel()
            }
            .keyboardShortcut(.cancelAction)

            BrowserJetAppButton(
                title: "Save",
                type: .primaryLarge,
                width: .fixed(width: 100),
                isDisabled: !viewModel.canSave
            ) {
                viewModel.save()
            }
            .keyboardShortcut(.defaultAction)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }
}

#Preview {
    SettingsView(themeManager: ThemeManager())
        .environmentObject(ThemeManager())
        .browserJetThemedRoot(themeManager: ThemeManager(), colorScheme: .light)
}
