//
//  BrowserTabItem.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 16/02/2026.
//

import Foundation
import AppKit

struct BrowserTabItem: Identifiable, Hashable {
    let id: UUID
    var title: String
    var isLoading: Bool
    var favicon: NSImage?

    init(
        id: UUID = UUID(),
        title: String,
        isLoading: Bool = false,
        favicon: NSImage? = nil
    ) {
        self.id = id
        self.title = title
        self.isLoading = isLoading
        self.favicon = favicon
    }
}

extension BrowserTabItem {
    @MainActor
    init(from tab: TabModel) {
        self.id = tab.id
        self.title = tab.title
        self.isLoading = tab.isLoading
        self.favicon = tab.favicon
    }
}
