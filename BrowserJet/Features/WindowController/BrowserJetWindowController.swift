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
/// title bar's drag region. Tab selection lives in an `NSTitlebarAccessoryViewController`,
/// so this band covers only the traffic-light row above the tab strip.
private final class BrowserJetWindow: NSWindow {
    /// Height of the draggable titlebar row above the tab-strip accessory.
    private static let titleBarDoubleClickBand: CGFloat = 28

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

final class BrowserJetWindowController<Content: View>: NSWindowController, ShowableWindowController {
    /// - Parameter size: Pass a fixed `NSSize` to pin the window to exact dimensions (existing
    ///   behaviour for activation, launcher, and browser windows). Pass `nil` to let the window
    ///   measure its own size from the SwiftUI content via `NSHostingController.sizingOptions =
    ///   .preferredContentSize` — useful for content-driven panels like About.
    convenience init(
        titledWindowTitle: String? = nil,
        content: Content,
        size: NSSize? = nil,
        titleBarHidden: Bool = false,
        resizable: Bool = false,
        cornerRadius: CGFloat = 16,
        borderlessChrome: Bool = false
    ) {
        let hosting = NSHostingController(rootView: content)

        let styleMask: NSWindow.StyleMask = {
            if borderlessChrome {
                return [.borderless, .fullSizeContentView]
            }

            var mask: NSWindow.StyleMask = [
                .titled,
                .closable,
                .miniaturizable,
                .fullSizeContentView
            ]

            if resizable {
                mask.insert(.resizable)
            }

            return mask
        }()

        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: size ?? .zero),
            styleMask: styleMask,
            backing: .buffered,
            defer: false
        )

        window.isReleasedWhenClosed = false

        // MARK: - Chrome

        window.title = titledWindowTitle ?? ""
        window.titleVisibility = titleBarHidden ? .hidden : .visible
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.toolbar = nil

        // MARK: - Visual

        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true

        // MARK: - Hosting View + Size

        if let fixedSize = size {
            // Fixed-size path: hosting view is added as a subview and clipped to the window.
            if let contentView = window.contentView {
                contentView.wantsLayer = true
                contentView.layer?.cornerRadius = cornerRadius
                contentView.layer?.masksToBounds = true

                hosting.view.translatesAutoresizingMaskIntoConstraints = true
                hosting.view.autoresizingMask = [.width, .height]
                hosting.view.frame = contentView.bounds
                hosting.view.wantsLayer = true
                hosting.view.layer?.cornerRadius = cornerRadius
                hosting.view.layer?.masksToBounds = true

                contentView.addSubview(hosting.view)
            }

            if !resizable {
                window.setContentSize(fixedSize)
                window.minSize = fixedSize
                window.maxSize = fixedSize

                if !borderlessChrome {
                    window.standardWindowButton(.zoomButton)?.isEnabled = false
                }
            }
        } else {
            // Content-driven path: the window measures its own size from the SwiftUI
            // view's preferred content size. No hardcoded height needed.
            hosting.sizingOptions = .preferredContentSize
            window.contentViewController = hosting

            if let contentView = window.contentView {
                contentView.wantsLayer = true
                contentView.layer?.cornerRadius = cornerRadius
                contentView.layer?.masksToBounds = true
            }

            hosting.view.wantsLayer = true
            hosting.view.layer?.cornerRadius = cornerRadius
            hosting.view.layer?.masksToBounds = true

            if !resizable, !borderlessChrome {
                window.standardWindowButton(.zoomButton)?.isEnabled = false
            }
        }

        window.center()

        self.init(window: window)

        AppLogger.debug("BrowserJetWindowController initialized successfully")
    }

    func applyFixedContentSize(_ size: NSSize) {
        guard let window else { return }
        // When the window uses fullSizeContentView with a visible title bar, SwiftUI
        // lays out content within the safe area (below the title bar). The measured
        // SwiftUI height therefore excludes the title bar. Add the title bar height so
        // the window is tall enough for both the title bar overlay and the full content.
        let titleBarAdjustment: CGFloat = {
            guard window.styleMask.contains(.titled),
                  window.styleMask.contains(.fullSizeContentView) else { return 0 }
            return max(0, window.frame.height - window.contentLayoutRect.height)
        }()

        let adjusted = NSSize(width: size.width, height: size.height + titleBarAdjustment)
        let clamped = NSSize(
            width: max(200, adjusted.width),
            height: max(120, adjusted.height)
        )

        window.setContentSize(clamped)

        if !window.styleMask.contains(.resizable) {
            window.minSize = clamped
            window.maxSize = clamped
        }

        window.center()
        window.invalidateShadow()

        AppLogger.debug("BrowserJetWindowController content size → \(clamped.width)x\(clamped.height)")
    }

    func setActivationChromeBorderless(_ borderless: Bool) {
        guard let window else { return }

        if borderless {
            window.styleMask = [.borderless, .fullSizeContentView]
            window.titleVisibility = .hidden
        } else {
            var mask: NSWindow.StyleMask = [
                .titled,
                .closable,
                .miniaturizable,
                .fullSizeContentView
            ]

            if window.styleMask.contains(.resizable) {
                mask.insert(.resizable)
            }

            window.styleMask = mask
            window.titleVisibility = .hidden
            window.standardWindowButton(.zoomButton)?.isEnabled = false
        }

        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.toolbar = nil

        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true

        if let contentView = window.contentView {
            contentView.wantsLayer = true
            contentView.layer?.masksToBounds = true
            contentView.layer?.cornerRadius = contentView.layer?.cornerRadius ?? 18
        }

        window.invalidateShadow()
    }

    func show() {
        NSApp.activate(ignoringOtherApps: true)

        guard let window else { return }

        window.makeKeyAndOrderFront(nil)

        let isResizable = window.styleMask.contains(.resizable)
        let isTitledWindow = window.styleMask.contains(.titled)

        if isResizable, isTitledWindow {
            window.center()

            if !window.isZoomed {
                window.zoom(nil)
            }
        }

        DispatchQueue.main.async {
            self.window?.makeFirstResponder(nil)
        }

        AppLogger.info("Window shown")
    }

    override func close() {
        window?.close()
        AppLogger.info("Window closed")
    }

    /// Hosts the tab strip in the native titlebar accessory area so tab interactions
    /// are not intercepted by the window drag region.
    func attachBrowserTabStripTitlebarAccessory(
        state: BrowserWindowState,
        themeManager: ThemeManager,
        sessionManager: SessionManager
    ) {
        guard let window else { return }

        let resolvedScheme = themeManager.resolvedColorScheme(for: .light)

        let accessory = BrowserTabStripTitlebarAccessory(
            state: state,
            themeManager: themeManager,
            sessionManager: sessionManager,
            resolvedColorScheme: resolvedScheme
        )
        window.addTitlebarAccessoryViewController(accessory)
    }
}

// MARK: - Last-window close confirmation
extension BrowserJetWindowController {
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        guard isLastVisibleAppWindow(closing: sender) else { return true }
        return QuitConfirmationController.confirmClosingLastWindow()
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
        guard isLastVisibleAppWindow(closing: sender) else { return true }
        return QuitConfirmationController.confirmClosingLastWindow()
    }

    private func isLastVisibleAppWindow(closing: NSWindow) -> Bool {
        NSApp.windows.filter { window in
            window !== closing && window.isVisible && !window.isSheet
        }.isEmpty
    }
}
