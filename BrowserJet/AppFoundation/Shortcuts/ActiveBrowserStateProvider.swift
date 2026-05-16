//
//  ActiveBrowserStateProvider.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 16/05/2026.
//

import Foundation

@MainActor
final class ActiveBrowserStateProvider: ObservableObject {
    static let shared = ActiveBrowserStateProvider()
    
    @Published var current: BrowserWindowState?
    
    private init() {}
}
