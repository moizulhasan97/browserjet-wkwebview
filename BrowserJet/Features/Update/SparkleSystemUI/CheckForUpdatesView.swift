//
//  CheckForUpdatesView.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 28/04/2026.
//

import SwiftUI
import Sparkle
import Combine

final class CheckForUpdatesViewModel: ObservableObject {
    @Published var canCheckForUpdates = false
    private var cancellable: AnyCancellable?
    
    init(updater: SPUUpdater) {
        cancellable = updater.publisher(for: \.canCheckForUpdates)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.canCheckForUpdates = value
            }
    }
    
    deinit {
        cancellable?.cancel()
    }
}

struct CheckForUpdatesView: View {
    @StateObject private var model: CheckForUpdatesViewModel
    private let updater: SPUUpdater
    
    init(updater: SPUUpdater) {
        self.updater = updater
        _model = StateObject(wrappedValue: CheckForUpdatesViewModel(updater: updater))
    }
    
    var body: some View {
        Button("Check for Updates…") {
            updater.checkForUpdates()
        }
        .disabled(!model.canCheckForUpdates)
    }
}
