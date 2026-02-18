//
//  BrowserJetWindowController.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 12/02/2026.
//


import AppKit
import SwiftUI

protocol ShowableWindowController: AnyObject {
    func show()
}

final class BrowserJetWindowController<Content: View>: NSWindowController, ShowableWindowController {
    convenience init(
        content: Content,
        size: NSSize,
        titleBarHidden: Bool = true,
        resizable: Bool = false,
        cornerRadius: CGFloat = 16
    ) {
        AppLogger.debug("Initializing BrowserJetWindowController - Size: \(size.width)x\(size.height), Resizable: \(resizable), CornerRadius: \(cornerRadius)")
        let hosting = NSHostingController(rootView: content)

        var styleMask: NSWindow.StyleMask = [
            .titled,
            .closable,
            .miniaturizable
        ]
        if resizable {
            styleMask.insert(.resizable)
        }

        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: styleMask,
            backing: .buffered,
            defer: false
        )

        window.contentViewController = hosting
        window.isReleasedWhenClosed = false

        // Fixed size (prevents resize by drag + green button)
        if !resizable {
            window.setContentSize(size)
            window.minSize = size
            window.maxSize = size
            window.standardWindowButton(.zoomButton)?.isEnabled = false
        }

        // Titlebar / title
        window.title = ""
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = false

        window.styleMask.insert(.fullSizeContentView)

        // Rounded corners
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.contentView?.wantsLayer = true
        window.contentView?.layer?.cornerRadius = cornerRadius
        window.contentView?.layer?.masksToBounds = true

        // Center on screen
        window.center()

        self.init(window: window)
        AppLogger.debug("BrowserJetWindowController initialized successfully")
    }

    func show() {
        AppLogger.debug("Showing window")
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
        
        if let window {
            window.zoom(nil)
        }
        
        DispatchQueue.main.async {
            self.window?.makeFirstResponder(nil)
        }
        AppLogger.info("Window activated and made key")
    }
}
