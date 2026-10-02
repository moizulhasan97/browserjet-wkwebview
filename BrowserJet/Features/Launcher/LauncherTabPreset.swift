//
//  LauncherTabPreset.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 12/02/2026.
//

enum LauncherTabPreset: Int, CaseIterable, Hashable {
    case one = 1
    case three = 3
    case five = 5
    case ten = 10
    case twenty = 20
    case thirty = 30
}

extension LauncherTabPreset {
    /// Launcher "No. of Tabs" options for a plan: the standard presets up to `maxTabs`, plus `maxTabs` itself.
    /// Why include `maxTabs`: Remote Config can set any limit (e.g. 7); the user must still be able to pick it.
    static func tabCountOptions(
        upTo maxTabs: Int,
        presets: [LauncherTabPreset] = LauncherTabPreset.allCases
    ) -> [Int] {
        var options = Set(presets.map(\.rawValue).filter { $0 <= maxTabs })
        options.insert(maxTabs)
        return options.sorted()
    }
}
