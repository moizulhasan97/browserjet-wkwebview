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
    func close()
    /// Fixed-size windows only: shrink/grow content area and re-center (no-op for types that don’t support it).
    func applyFixedContentSize(_ size: NSSize)
    /// Activation bootstrap only: hide titled window chrome so only the card is visible.
    func setActivationChromeBorderless(_ borderless: Bool)
}

extension ShowableWindowController {
    func applyFixedContentSize(_ size: NSSize) {}
    func setActivationChromeBorderless(_ borderless: Bool) {}
}

final class BrowserJetWindowController<Content: View>: NSWindowController, ShowableWindowController {
    convenience init(
        titledWindowTitle: String? = nil,
        content: Content,
        size: NSSize,
        titleBarHidden: Bool = true,
        resizable: Bool = false,
        cornerRadius: CGFloat = 16,
        /// No traffic lights or title bar — window frame matches content (e.g. stored-key verify card).
        borderlessChrome: Bool = false
    ) {
        // swiftlint:disable:next line_length
        AppLogger.debug("Initializing BrowserJetWindowController - Size: \(size.width)x\(size.height), Resizable: \(resizable), CornerRadius: \(cornerRadius), borderless: \(borderlessChrome)")
        let hosting = NSHostingController(rootView: content)

        let styleMask: NSWindow.StyleMask = {
            if borderlessChrome {
                return [.borderless, .fullSizeContentView]
            }
            var mask: NSWindow.StyleMask = [.titled, .closable, .miniaturizable, .fullSizeContentView]
            if resizable {
                mask.insert(.resizable)
            }
            return mask
        }()

        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: styleMask,
            backing: .buffered,
            defer: false
        )

        window.contentViewController = hosting
        window.isReleasedWhenClosed = false

        if !resizable {
            window.setContentSize(size)
            window.minSize = size
            window.maxSize = size
            if !borderlessChrome {
                window.standardWindowButton(.zoomButton)?.isEnabled = false
            }
        }

        if let titledWindowTitle {
            window.title = titledWindowTitle
            window.titleVisibility = .visible
        } else {
            window.title = ""
            window.titleVisibility = .hidden
        }
        window.titlebarAppearsTransparent = borderlessChrome
        window.isMovableByWindowBackground = borderlessChrome

        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.contentView?.wantsLayer = true
        window.contentView?.layer?.cornerRadius = cornerRadius
        window.contentView?.layer?.masksToBounds = true

        window.center()

        self.init(window: window)
        AppLogger.debug("BrowserJetWindowController initialized successfully")
    }

    func applyFixedContentSize(_ size: NSSize) {
        guard let window else { return }
        let clamped = NSSize(
            width: max(200, size.width),
            height: max(120, size.height)
        )
        window.setContentSize(clamped)
        if !window.styleMask.contains(.resizable) {
            window.minSize = clamped
            window.maxSize = clamped
        }
        window.center()
        AppLogger.debug("BrowserJetWindowController content size → \(clamped.width)x\(clamped.height)")
    }

    func setActivationChromeBorderless(_ borderless: Bool) {
        guard let window else { return }
        if borderless {
            window.styleMask = [.borderless, .fullSizeContentView]
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            window.isMovableByWindowBackground = true
        } else {
            var mask: NSWindow.StyleMask = [.titled, .closable, .miniaturizable, .fullSizeContentView]
            if window.styleMask.contains(.resizable) {
                mask.insert(.resizable)
            }
            window.styleMask = mask
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = false
            window.isMovableByWindowBackground = false
            window.standardWindowButton(.zoomButton)?.isEnabled = false
        }
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.contentView?.wantsLayer = true
        let radius = window.contentView?.layer?.cornerRadius ?? 18
        window.contentView?.layer?.cornerRadius = radius
        window.contentView?.layer?.masksToBounds = true
        window.invalidateShadow()
        AppLogger.debug("BrowserJetWindowController borderless chrome → \(borderless)")
    }

    func show() {
        AppLogger.debug("Showing window")
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)

        if let window,
           !window.styleMask.contains(.borderless),
           window.styleMask.contains(.resizable) {
            window.zoom(nil)
        }

        DispatchQueue.main.async {
            self.window?.makeFirstResponder(nil)
        }
        AppLogger.info("Window activated and made key")
    }

    override func close() {
        AppLogger.debug("Closing window")
        window?.close()
        AppLogger.info("Window closed")
    }
}
