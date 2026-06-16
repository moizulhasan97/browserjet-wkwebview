//
//  BrowserMoreMenuItem.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 20/02/2026.
//

import Foundation

enum BrowserMoreMenuItem: Hashable, CaseIterable {
    case paymentCard
    case buyLicenses
    case contactUs
    case changeKey
    //case about
    case twitter

    var title: String {
        switch self {
        case .paymentCard: return "Enter/Update Your Payment Card"
        case .buyLicenses: return "Buy More Licenses"
        case .contactUs: return "Contact Us"
        case .changeKey: return "Change Your Key"
        //case .about: return "About Browser Jet"
        case .twitter: return "Connect Us (Twitter)"
        }
    }

    var isEnabled: Bool { true }
}
