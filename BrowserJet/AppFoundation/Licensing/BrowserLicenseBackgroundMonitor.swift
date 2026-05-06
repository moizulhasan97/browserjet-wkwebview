//
//  BrowserLicenseBackgroundMonitor.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 05/05/2026.
//

import AppKit

enum BrowserLicenseBackgroundMonitor {
    
//    private static let verifyKeyPollInterval: UInt64 = 10.seconds
//    //private static let checkExpiryPollInterval: UInt64 = 10.seconds //30.minutes
//    private static let macFailureTerminateDelay: UInt64 = 10.seconds
//    private static let keyExpiredTerminateDelay: UInt64 = 30.minutes
    
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
        
            //await withTaskGroup(of: Void.self) { group in
            //group.addTask {
                await verifyKeyPollLoop(
                    key: key,
                    licenseService: licenseService,
                    licenseStore: licenseStore,
                    keyValueStore: keyValueStore
                )
            //}
//            group.addTask {
//                await checkExpiryPollLoop(key: key, licenseService: licenseService)
//            }
                //}
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
                // TODO: - Remove this after confirming with Ebad bhai
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
                AppLogger.warning("BrowserLicenseBackgroundMonitor: verifyKey poll failed — \(error.localizedDescription)")
            }
        }
    }
    
//    private static func checkExpiryPollLoop(key: String, licenseService: LicenseService) async {
//        while !Task.isCancelled {
//            do {
//                try await Task.sleep(nanoseconds: checkExpiryPollInterval)
//                let expired = try await licenseService.checkKeyExpiry(key)
//                if expired {
//                    await presentKeyExpiredAndQuit()
//                    return
//                }
//            } catch is CancellationError {
//                return
//            } catch {
//                AppLogger.warning("BrowserLicenseBackgroundMonitor: checkKeyExpiry poll failed — \(error.localizedDescription)")
//            }
//        }
//    }
    
    @MainActor
    private static func presentMacVerificationFailedAndQuit() async {
        let alert = NSAlert()
        alert.messageText = AppGraceShutdown.alertTitle
        alert.informativeText = AppGraceShutdown.macMismatchQuitMessage()
        alert.alertStyle = .critical
        alert.addButton(withTitle: "OK")
        alert.runModal()
        try? await Task.sleep(nanoseconds: AppGraceShutdown.Timing.macMismatchQuit)
        NSApplication.shared.terminate(nil)
    }
    
    @MainActor
    private static func presentKeyExpiredAndQuit() async {
        let alert = NSAlert()
        alert.messageText = AppGraceShutdown.alertTitle
        alert.informativeText = AppGraceShutdown.keyExpiredQuitMessage(forDelayNanoseconds: AppGraceShutdown.Timing.keyExpiredQuit)
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
        try? await Task.sleep(nanoseconds: AppGraceShutdown.Timing.keyExpiredQuit)
        NSApplication.shared.terminate(nil)
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
