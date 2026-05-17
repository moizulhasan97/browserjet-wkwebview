//
//  AppDelegate.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 16/05/2026.
//

import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        QuitConfirmationController.applicationShouldTerminate()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}
