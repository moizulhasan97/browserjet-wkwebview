//
//  ForceUpdateBlockingOverlay.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 28/04/2026.
//

import SwiftUI
import Sparkle

struct ForceUpdateBlockingOverlay: View {
    @ObservedObject private var gate = ForceUpdateGate.shared
    @Environment(\.appTheme) private var theme
    @Environment(\.designSystem) private var designSystem
    
    var body: some View {
        if gate.isBlocking {
            ZStack {
                Color.black.opacity(0.55)
                    .ignoresSafeArea()
                
                InfoAlertChrome(minWidth: 380, maxWidth: 440) {
                    VStack(spacing: 18) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 38, weight: .medium))
                            .foregroundStyle(theme.danger)
                        
                        VStack(spacing: 10) {
                            Text("Update Required")
                                .font(designSystem.typography.title1.font)
                                .foregroundStyle(theme.textPrimary)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                            
                            Text("You’re using an outdated version of BrowserJet. Please update to continue.")
                                .font(designSystem.typography.textBody1.font)
                                .foregroundStyle(theme.textFieldSecondary)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Current: \(gate.currentMarketing) (\(gate.currentBuild))")
                            Text("Required: \(gate.requiredMarketing) (\(gate.requiredBuild))+")
                        }
                        .font(designSystem.typography.textBody2.font)
                        .monospacedDigit()
                        .foregroundStyle(theme.textFieldSecondary.opacity(0.85))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 4)
                        
                        VStack(spacing: 12) {
                            BrowserJetAppButton(
                                title: "Update Now",
                                type: .primaryLarge,
                                height: 48,
                                isDisabled: false,
                                action: {
                                    gate.updateNowTapped()
                                }
                            )
                            
                            if gate.manualDownloadURL != nil {
                                BrowserJetAppButton(
                                    title: "Download manually",
                                    type: .secondaryLarge,
                                    height: 44,
                                    isDisabled: false,
                                    action: {
                                        gate.openManualDownloadPage()
                                    }
                                )
                            }
                            
                            BrowserJetAppButton(
                                title: "Quit BrowserJet",
                                type: .destructivePrimaryLarge,
                                height: 44,
                                isDisabled: false,
                                action: { gate.quitApplication() }
                            )
                            .padding(.top, 4)
                        }
                        .padding(.top, 4)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .allowsHitTesting(true)
        }
    }
}

#Preview("Force update overlay") {
    ZStack {
        AppBackgroundStyle.browserJetGradient.makeView()
        ForceUpdateBlockingOverlay()
    }
    .environment(\.appTheme, BrowserJetDarkTheme())
    .environment(\.designSystem, DesignSystem())
    .onAppear {
        ForceUpdateGate.shared.register(updaterController: SPUStandardUpdaterController(
            startingUpdater: false,
            updaterDelegate: nil,
            userDriverDelegate: nil
        ))
        ForceUpdateGate.shared.activateRequiredUpdate(
            currentMarketing: "3.7.0",
            currentBuild: 2,
            requiredMarketing: "3.8.0",
            requiredBuild: 7,
            manualDownloadURL: URL(string: "https://example.com")
        )
    }
}
