//
//  BrowserCommands.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 16/05/2026.
//

import SwiftUI

//  Wires keyboard shortcuts into the macOS main menu using SwiftUI commands.
struct BrowserCommands: Commands {
    
    let themeManager: ThemeManager
    
    @ObservedObject private var provider = ActiveBrowserStateProvider.shared
    
    private var state: BrowserWindowState? { provider.current }
    
    private var isAllowed: Bool {
        ShortcutsAvailability.isAllowed(for: state)
    }
    
    private var hasTabs: Bool {
        (state?.tabs.count ?? 0) > 0
    }
    
    private var canReopen: Bool {
        !(state?.closedTabsStack.isEmpty ?? true)
    }
    
    var body: some Commands {
        // MARK: Close (Cmd+W) — replaces system Save/Close group (.saveItem)
        CommandGroup(replacing: .saveItem) {
            Button(state == nil ? "Close Window" : "Close Tab") {
                if let state {
                    state.requestCloseSelectedTab()
                } else {
                    NSApp.keyWindow?.close()
                }
            }
            .keyboardShortcut("w", modifiers: .command)
            .disabled(state == nil && NSApp.keyWindow == nil)
        }

        // MARK: File menu — tab lifecycle
        CommandGroup(after: .newItem) {
            Divider()
            
            Button("New Tab") { state?.addTab() }
                .keyboardShortcut("t", modifiers: .command)
                .disabled(!isAllowed)
            
            Button("Reopen Last Closed Tab") { state?.reopenLastClosedTab() }
                .keyboardShortcut("t", modifiers: [.command, .shift])
                .disabled(!isAllowed || !canReopen)
            
            Button("Duplicate Tab") { state?.duplicateSelectedTab(count: 1) }
                .keyboardShortcut("t", modifiers: [.command, .option])
                .disabled(!isAllowed || !hasTabs)
        }
        
        // MARK: View menu — page actions
        CommandGroup(after: .toolbar) {
            Button("Reload Tab") { state?.reloadSelectedTab() }
                .keyboardShortcut("r", modifiers: .command)
                .disabled(state == nil || !hasTabs)
            
            Button("Reload All Tabs") { state?.reloadAllTabs() }
                .keyboardShortcut("r", modifiers: [.command, .shift])
                .disabled(!isAllowed || !hasTabs)
            
            Divider()
            
            Button("Back") { state?.goBackSelectedTab() }
                .keyboardShortcut("[", modifiers: .command)
                .disabled(!isAllowed || !(state?.selectedTab?.canGoBack ?? false))
            
            Button("Forward") { state?.goForwardSelectedTab() }
                .keyboardShortcut("]", modifiers: .command)
                .disabled(!isAllowed || !(state?.selectedTab?.canGoForward ?? false))
            
            Divider()
            
            Button("Zoom In") { state?.zoomInSelectedTab() }
                .keyboardShortcut("+", modifiers: .command)
                .disabled(!isAllowed || !hasTabs)
            
            Button("Zoom Out") { state?.zoomOutSelectedTab() }
                .keyboardShortcut("-", modifiers: .command)
                .disabled(!isAllowed || !hasTabs)
            
            Button("Actual Size") { state?.zoomResetSelectedTab() }
                .keyboardShortcut("0", modifiers: .command)
                .disabled(!isAllowed || !hasTabs)
            
            Divider()
            
            Button("Focus Address Bar") { state?.requestFocusAddressBar() }
                .keyboardShortcut("l", modifiers: .command)
                .disabled(!isAllowed || !hasTabs)
            
            Button("Take Screenshot") { state?.takeScreenshotOfSelectedTab() }
                .keyboardShortcut("s", modifiers: [.command, .shift])
                .disabled(!isAllowed || !hasTabs)
            
            Button("Burn IP and Reload") { state?.burnProxyAndReloadSelectedTab() }
                .keyboardShortcut("b", modifiers: [.command, .shift])
                .disabled(!isAllowed || !hasTabs)
        }
        
        // MARK: Tab menu — selection
        CommandMenu("Tab") {
            Button("Next Tab") { state?.selectNextTab() }
                .keyboardShortcut(.rightArrow, modifiers: [.command, .option])
                .disabled(!isAllowed || (state?.tabs.count ?? 0) < 2)
            
            Button("Previous Tab") { state?.selectPreviousTab() }
                .keyboardShortcut(.leftArrow, modifiers: [.command, .option])
                .disabled(!isAllowed || (state?.tabs.count ?? 0) < 2)
            
            Divider()
            
            ForEach(1...8, id: \.self) { index in
                Button("Switch to Tab \(index)") {
                    state?.selectTab(at: index - 1)
                }
                .keyboardShortcut(KeyEquivalent(Character("\(index)")), modifiers: .command)
                .disabled(!isAllowed || (state?.tabs.count ?? 0) < index)
            }
            
            Button("Switch to Last Tab") { state?.selectLastTab() }
                .keyboardShortcut("9", modifiers: .command)
                .disabled(!isAllowed || !hasTabs)
        }
        
        // MARK: About BrowserJet
        CommandGroup(replacing: .appInfo) {
            Button("About BrowserJet") {
                showAboutWindow()
            }
        }
    }
    
    private func showAboutWindow() {
        let scheme: ColorScheme = (NSApp.effectiveAppearance.bestMatch(
            from: [.aqua, .darkAqua]
        ) == .darkAqua) ? .dark : .light
        
        let licenseStore = LicenseStore()
        let canPresentCustom = licenseStore.load().map(AboutBrowserJetContentBuilder.canPresent) ?? false
        
        if canPresentCustom {
            AboutBrowserJetWindowController.shared.show(
                themeManager: themeManager,
                colorScheme: scheme
            )
        } else {
            // Pre-activation / ineligible license: fall back to the standard
            // macOS About panel so the menu item never feels "broken".
            //NSApplication.shared.orderFrontStandardAboutPanel(nil)
            presentSystemAboutPanel()
        }
    }
    
    private func presentSystemAboutPanel() {
        NSApplication.shared.orderFrontStandardAboutPanel(
            options: AboutPanelOptionsBuilder.build()
        )
    }
}
