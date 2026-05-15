//
//  SystemInfo 2.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 24/02/2026.
//

import Foundation
import IOKit

enum SystemInfo {
    /// Falls back to the hostname if the display name is unavailable.
    static func currentComputerName() -> String {
        Host.current().localizedName ?? ProcessInfo.processInfo.hostName
    }

    /// Returns an empty string if IOKit cannot provide it (e.g. in a sandboxed test target).
    static func macSerialNumber() -> String {
        var serialNumber = ""

        let platformExpert = IOServiceGetMatchingService(
            kIOMainPortDefault,
            IOServiceMatching("IOPlatformExpertDevice")
        )

        guard platformExpert != 0 else {
            AppLogger.warning("SystemInfo: IOPlatformExpertDevice not found")
            return serialNumber
        }

        defer { IOObjectRelease(platformExpert) }

        if let serial = IORegistryEntryCreateCFProperty(
            platformExpert,
            "IOPlatformSerialNumber" as CFString,
            kCFAllocatorDefault,
            0
        )?.takeRetainedValue() as? String {
            serialNumber = serial
        } else {
            AppLogger.warning("SystemInfo: IOPlatformSerialNumber unavailable")
        }

        return serialNumber
    }
}
