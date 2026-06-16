//
//  BrowserWindowState+Screenshot.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 16/06/2026.
//

import AppKit
import WebKit

extension BrowserWindowState {
    // MARK: Screenshot
    func takeScreenshotOfSelectedTab() {
        guard let tab = selectedTab else { return }
        let config = WKSnapshotConfiguration()
        tab.webView.takeSnapshot(with: config) { [weak self] image, error in
            if let error {
                AppLogger.error("Screenshot failed: \(error.localizedDescription)")
                return
            }
            guard let image else {
                AppLogger.error("Screenshot failed: no image")
                return
            }
            guard let tiff = image.tiffRepresentation,
                let rep = NSBitmapImageRep(data: tiff),
                let png = rep.representation(using: .png, properties: [:]) else {
                AppLogger.error("Screenshot failed: could not encode PNG")
                return
            }

            DispatchQueue.main.async {
                self?.presentSavePanel(pngData: png)
            }
        }
    }

    private func presentSavePanel(pngData: Data) {
        let panel = NSSavePanel()
        panel.title = "Save Screenshot"
        panel.nameFieldLabel = "Save As:"
        panel.nameFieldStringValue = "BrowserJet-\(Int(Date().timeIntervalSince1970)).png"
        panel.allowedContentTypes = [.png]
        panel.canCreateDirectories = true

        // Default to Desktop
        if let desktop = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first {
            panel.directoryURL = desktop
        }

        guard panel.runModal() == .OK, let url = panel.url else {
            AppLogger.info("Screenshot save cancelled by user")
            return
        }

        do {
            try pngData.write(to: url)
            AppLogger.info("Screenshot saved: \(url.path)")
            NSWorkspace.shared.activateFileViewerSelecting([url])
        } catch {
            AppLogger.error("Screenshot save failed: \(error.localizedDescription)")
        }
    }
}
