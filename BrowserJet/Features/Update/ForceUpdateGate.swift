//
//  ForceUpdateGate.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 28/04/2026.
//

import Combine
import Foundation
import Sparkle
import AppKit

@MainActor
final class ForceUpdateGate: ObservableObject {
    static let shared = ForceUpdateGate()
    
    @Published private(set) var isBlocking = false
    @Published private(set) var currentMarketing: String = ""
    @Published private(set) var currentBuild: Int = 0
    @Published private(set) var requiredMarketing: String = ""
    @Published private(set) var requiredBuild: Int = 0
    @Published private(set) var manualDownloadURL: URL?
    
    private weak var updaterController: SPUStandardUpdaterController?
    
    private init() {}
    
    func register(updaterController: SPUStandardUpdaterController) {
        self.updaterController = updaterController
    }
    
    /// Call from policy when user must update before continuing.
    func activateRequiredUpdate(
        currentMarketing: String,
        currentBuild: Int,
        requiredMarketing: String,
        requiredBuild: Int,
        manualDownloadURL: URL? = nil
    ) {
        self.currentMarketing = currentMarketing
        self.currentBuild = currentBuild
        self.requiredMarketing = requiredMarketing
        self.requiredBuild = requiredBuild
        self.manualDownloadURL = manualDownloadURL
        isBlocking = true
    }
    
    func retryUpdateTapped() {
        updateNowTapped()
    }
    
    func openManualDownloadPage() {
        guard let url = manualDownloadURL else { return }
        NSWorkspace.shared.open(url)
    }
    
    func updateNowTapped() {
        updaterController?.checkForUpdates(nil)
    }
    
    func quitApplication() {
        QuitConfirmationController.terminateWithoutConfirmation()
    }
}
