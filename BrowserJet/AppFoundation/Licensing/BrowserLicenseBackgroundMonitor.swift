//
//  BrowserLicenseBackgroundMonitor.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 05/05/2026.
//

import AppKit

enum BrowserLicenseBackgroundMonitor {
    static func run(
        licenseService: LicenseService = LicenseService(),
        licenseStore: LicenseStore = LicenseStore(),
        keyValueStore: KeyValueStoring = UserDefaultsKeyValueStore()
    ) async {
        guard let persisted = licenseStore.load(),
            persisted.isEligibleForBackgroundLicenseMonitoring() else {
            AppLogger.debug("BrowserLicenseBackgroundMonitor: skipped (no persisted license or not eligible)")
            return
        }
        guard let key = trimmedLicenseKey(from: keyValueStore) else {
            AppLogger.debug("BrowserLicenseBackgroundMonitor: skipped (no license key in store)")
            return
        }

        await verifyKeyPollLoop(
            key: key,
            licenseService: licenseService,
            licenseStore: licenseStore,
            keyValueStore: keyValueStore
        )
    }

    private static func trimmedLicenseKey(from store: KeyValueStoring) -> String? {
        let raw = store.object(forKey: StorageKeys.licenseKey) as? String ?? ""
        let key = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return key.isEmpty ? nil : key
    }

    private static func verifyKeyPollLoop(
        key: String,
        licenseService: LicenseService,
        licenseStore: LicenseStore,
        keyValueStore: KeyValueStoring
    ) async {
        while !Task.isCancelled {
            do {
                try await Task.sleep(nanoseconds: AppGraceShutdown.Timing.verifyKeyPollInterval)
                let response = try await licenseService.verifyKey(key)
                if response.userStatus == .rejected {
                    await presentMacVerificationFailedAndQuit()
                    return
                }
                let now = Date()
                if Self.isAccessExpiredForBackground(response: response, referenceNow: now) {
                    AppLogger.info("BrowserLicenseBackgroundMonitor: access expired per VerifyKeyResponse")
                    await presentKeyExpiredAndQuit()
                    return
                }
                licenseStore.save(response)
                await MainActor.run {
                    LicenseAccountStore.shared.refresh()
                }
            } catch is CancellationError {
                return
            } catch {
                AppLogger.warning(
                    "BrowserLicenseBackgroundMonitor: verifyKey poll failed — \(error.localizedDescription)"
                )
            }
        }
    }

    @MainActor
    private static func presentGraceShutdownAlertAndQuit(
        message: String,
        style: NSAlert.Style,
        delayNanoseconds: UInt64
    ) {
        let alert = NSAlert()
        alert.messageText = AppGraceShutdown.alertTitle
        alert.informativeText = message
        alert.alertStyle = style
        alert.addButton(withTitle: "OK")

        let delaySeconds = Double(delayNanoseconds) / 1_000_000_000
        var terminated = false

        var autoQuitTimer: Timer?
        autoQuitTimer = Timer(timeInterval: delaySeconds, repeats: false) { _ in
            NSApp.stopModal(withCode: .alertFirstButtonReturn)
            DispatchQueue.main.async {
                guard !terminated else { return }
                terminated = true
                QuitConfirmationController.terminateWithoutConfirmation()
            }
        }
        RunLoop.main.add(autoQuitTimer!, forMode: .modalPanel)
        RunLoop.main.add(autoQuitTimer!, forMode: .default)

        alert.runModal()

        autoQuitTimer?.invalidate()
        autoQuitTimer = nil
        guard !terminated else { return }
        terminated = true
        QuitConfirmationController.terminateWithoutConfirmation()
    }

    @MainActor
    private static func presentMacVerificationFailedAndQuit() async {
        presentGraceShutdownAlertAndQuit(
            message: AppGraceShutdown.macMismatchQuitMessage(),
            style: .critical,
            delayNanoseconds: AppGraceShutdown.Timing.macMismatchQuit
        )
    }

    @MainActor
    private static func presentKeyExpiredAndQuit() async {
        presentGraceShutdownAlertAndQuit(
            message: AppGraceShutdown.keyExpiredQuitMessage(
                forDelayNanoseconds: AppGraceShutdown.Timing.keyExpiredQuit
            ),
            style: .informational,
            delayNanoseconds: AppGraceShutdown.Timing.keyExpiredQuit
        )
    }

    private static func isAccessExpiredForBackground(response: VerifyKeyResponse, referenceNow: Date) -> Bool {
        guard response.authenticationType == .verified else { return false }
        guard response.userStatus == .active else { return false }
        switch response.userKind {
        case .trial:
            return response.has5TabTrialCode || response.isTrialAccessExpiredByProxyDate(referenceNow: referenceNow)
        case .paid:
            return response.isUserLicenseExpired(referenceNow: referenceNow)
        }
    }
}
