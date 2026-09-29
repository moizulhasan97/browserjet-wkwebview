//
//  SessionManager.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 16/02/2026.
//

import Foundation

private enum SessionManagerFault: Error, LocalizedError {
    case slotAccountingMismatch(activeSessions: Int, maxSessions: Int)
    case invalidSlotIndexOnRelease(Int)
    case doubleReleaseOfSlot(Int)

    var errorDescription: String? {
        switch self {
        case .slotAccountingMismatch(let active, let max):
            return "SessionManager: canCreateSession was true (\(active)/\(max)) but no free slot found."
        case .invalidSlotIndexOnRelease(let slot):
            return "SessionManager: releaseSessionSlot called with out-of-range slot \(slot)."
        case .doubleReleaseOfSlot(let slot):
            return "SessionManager: releaseSessionSlot called for slot \(slot) already free."
        }
    }
}

@MainActor
final class SessionManager: ObservableObject {
    let maxSessions: Int

    private var slotInUse: [Bool]
    @Published private(set) var activeSessions: Int = 0 {
        didSet { AppLogger.debug("Active sessions changed to: \(activeSessions)/\(maxSessions)") }
    }

    init(maxSessions: Int = AppConfiguration.production.maxBrowserTabs) {
        self.maxSessions = maxSessions
        self.slotInUse = Array(repeating: false, count: maxSessions)
        AppLogger.debug("SessionManager initialized - Max sessions: \(maxSessions)")
    }

    var canCreateSession: Bool { activeSessions < maxSessions }

    func acquireSessionSlot() -> Int? {
        guard canCreateSession else {
            AppLogger.warning("Cannot acquire session slot - At capacity (\(activeSessions)/\(maxSessions))")
            return nil
        }
        guard let slot = slotInUse.firstIndex(where: { !$0 }) else {
            AppLogger.error("Failed to find available session slot despite canCreateSession being true")
            CrashReportingManager.shared.record(
                error: SessionManagerFault.slotAccountingMismatch(
                    activeSessions: activeSessions,
                    maxSessions: maxSessions
                )
            )
            return nil
        }
        slotInUse[slot] = true
        activeSessions += 1
        AppLogger.info("Session slot \(slot) acquired - Active sessions: \(activeSessions)/\(maxSessions)")
        return slot
    }

    func releaseSessionSlot(_ slot: Int) {
        guard slotInUse.indices.contains(slot) else {
            AppLogger.error("Attempted to release invalid session slot: \(slot)")
            CrashReportingManager.shared.record(error: SessionManagerFault.invalidSlotIndexOnRelease(slot))
            return
        }
        guard slotInUse[slot] else {
            AppLogger.warning("Attempted to release session slot \(slot) that was not in use")
            CrashReportingManager.shared.record(error: SessionManagerFault.doubleReleaseOfSlot(slot))
            return
        }
        slotInUse[slot] = false
        activeSessions = max(activeSessions - 1, 0)
        AppLogger.info("Session slot \(slot) released - Active sessions: \(activeSessions)/\(maxSessions)")
    }
}
