//
//  UserAgentPreset.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 18/07/2026.
//


enum UserAgentPreset: CaseIterable {
    /// Safari 26.5 desktop UA (macOS 10.15.7 build string / WebKit 605.1.15).
    case safariMacOS
}

extension UserAgentPreset {
    var rawUserAgentString: String {
        switch self {
        case .safariMacOS:
            return "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 "
                + "(KHTML, like Gecko) Version/26.5 Safari/605.1.15"
        }
    }
}