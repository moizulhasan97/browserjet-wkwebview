//
//  BrowserJetViewConfig.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 12/02/2026.
//

import Foundation

struct BrowserJetViewConfig: ViewConfig {
    var viewCornerRadius: CGFloat {
        8
    }

    var textFieldCornerRadius: CGFloat {
        8
    }

    var buttonCornerRadius: CornerRadius {
        .capsule
    }
}
