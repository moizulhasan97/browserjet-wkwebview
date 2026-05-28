//
//  BrowserJetWindowController.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 12/02/2026.
//

import AppKit
import SwiftUI

/// NSWindow subclass that forwards title-bar double-clicks to the standard
/// macOS title-bar action even when SwiftUI subviews (e.g. the tab strip's
/// `ScrollView`) cover the title bar via `.fullSizeContentView`.
///
/// AppKit only invokes the title-bar action when its hit-test lands on the
/// title bar's drag region; here the SwiftUI `NSClipView` swallows the
/// double-click first, so we re-implement the behavior by reading the user's
/// `AppleActionOnDoubleClick` preference and calling the matching window
/// action when a double-click lands in the top tab-strip band.
private final class BrowserJetWindow: NSWindow {
    /// Height of the band at the top of the window (standard title bar + custom
    /// tab strip) within which a double-click should emulate the macOS
    /// title-bar double-click action. Matches `BrowserTabsStripView.stripHeight`.
    private static let titleBarDoubleClickBand: CGFloat = 44
    
    override func sendEvent(_ event: NSEvent) {
        if event.type == .leftMouseDown,
           event.clickCount == 2,
           styleMask.contains(.titled),
           styleMask.contains(.fullSizeContentView) {
            let distFromTop = frame.height - event.locationInWindow.y
            if distFromTop >= 0, distFromTop <= Self.titleBarDoubleClickBand {
                performTitleBarDoubleClickAction()
            }
        }
        super.sendEvent(event)
    }
    
    private func performTitleBarDoubleClickAction() {
        let action = UserDefaults.standard.string(forKey: "AppleActionOnDoubleClick") ?? "Maximize"
        switch action {
        case "Minimize":
            performMiniaturize(nil)
        case "None":
            break
        default:
            performZoom(nil)
        }
    }
}

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

final class BrowserJetWindowController<Content: View>: NSWindowController,
                                                       ShowableWindowController {
    
    private let windowCloseDelegate = BrowserJetWindowCloseDelegate()
    
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
        
        let window = BrowserJetWindow(
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
        // Title bar is always transparent so the SwiftUI brand gradient can render
        // continuously through the title-bar safe area; AppKit still draws the
        // standard traffic lights on top.
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = borderlessChrome
        
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.contentView?.wantsLayer = true
        window.contentView?.layer?.cornerRadius = cornerRadius
        window.contentView?.layer?.masksToBounds = true
        
        window.center()
        
        self.init(window: window)
        window.delegate = windowCloseDelegate
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
            window.titlebarAppearsTransparent = true
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
        
        guard let window else { return }
        
        window.makeKeyAndOrderFront(nil)
        
        let isResizable = window.styleMask.contains(.resizable)
        let isTitledWindow = window.styleMask.contains(.titled)
        
        if isResizable,
           isTitledWindow,
           let screen = window.screen ?? NSScreen.main {
            window.setFrame(screen.visibleFrame, display: true, animate: false)
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

// MARK: - Last-window close confirmation
extension BrowserJetWindowController {
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        if shouldCloseSelectedTabInsteadOfWindow(for: sender) {
            ActiveBrowserStateProvider.shared.current?.requestCloseSelectedTab()
            return false
        }
        guard isLastVisibleAppWindow(closing: sender) else { return true }
        return QuitConfirmationController.confirmClosingLastWindow()
    }

    private func shouldCloseSelectedTabInsteadOfWindow(for sender: NSWindow) -> Bool {
        // Browser windows are the only resizable app windows. Intercepting
        // close here makes Cmd+W behave like "Close Tab" whenever possible.
        guard sender.styleMask.contains(.resizable),
              let state = ActiveBrowserStateProvider.shared.current,
              !state.isTrialLockActive,
              state.tabs.count > 1 else {
            return false
        }
        return true
    }

    private func isLastVisibleAppWindow(closing: NSWindow) -> Bool {
        NSApp.windows.filter { window in
            window !== closing && window.isVisible && !window.isSheet
        }.isEmpty
    }
}

/// Handles last-window close confirmation for BrowserJet windows.
/// Must be non-generic so `NSWindowDelegate` methods are visible to Obj-C.
@MainActor
final class BrowserJetWindowCloseDelegate: NSObject, NSWindowDelegate {

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        if shouldCloseSelectedTabInsteadOfWindow(for: sender) {
            ActiveBrowserStateProvider.shared.current?.requestCloseSelectedTab()
            return false
        }
        guard isLastVisibleAppWindow(closing: sender) else { return true }
        return QuitConfirmationController.confirmClosingLastWindow()
    }

    private func shouldCloseSelectedTabInsteadOfWindow(for sender: NSWindow) -> Bool {
        // Browser windows are the only resizable app windows. Intercepting
        // close here makes Cmd+W behave like "Close Tab" whenever possible.
        guard sender.styleMask.contains(.resizable),
              let state = ActiveBrowserStateProvider.shared.current,
              !state.isTrialLockActive,
              state.tabs.count > 1 else {
            return false
        }
        return true
    }

    private func isLastVisibleAppWindow(closing: NSWindow) -> Bool {
        NSApp.windows.filter { window in
            window !== closing && window.isVisible && !window.isSheet
        }.isEmpty
    }
}
