//
//  ManageMyProxyMessages.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 07/07/2026.
//


enum ManageMyProxyMessages {
    static let windowTitle = "Manage My Proxy"

    // Groups
    static let noGroupsYet = "No groups yet — create one below."
    static let loadingGroups = "Loading your proxy groups…"
    static let selectGroupPrompt = "Select a group to continue."

    // Proxies
    static let noProxiesInGroup = "No proxies in this group yet. Add one below or import a file."
    static let loadingProxies = "Loading proxies…"

    // Use My Proxy
    static let useMyProxyNeedsGroup = "Select a group with at least one proxy to continue."
    static let useMyProxyLoadingData = "Loading your proxy data…"

    // Import
    static let importFilePickerPrompt = "Choose a .csv or .txt file"
    static let importFormatHint = "One proxy per line: IP,PORT,USERNAME,PASSWORD or IP:PORT:USERNAME:PASSWORD"
    static let importSummaryTitle = "Import Complete"

    // Export
    static let exportDefaultFileName = "browserjet-proxies.csv"
    static let exportEmptyGroup = "This group has no proxies to export."

    // Status card (launcher)
    static let disableCustomProxy = "Disable"
}