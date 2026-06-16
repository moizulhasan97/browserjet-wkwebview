//
//  HeadingStyles.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 17/02/2026.
//

import Foundation

struct Heading1: Typography {
    var size: CGFloat {
        12.0
    }
    var fontProvider: FontProvider {
        .sfPro(weight: .semiBold)
    }
}

struct Heading4: Typography {
    var size: CGFloat {
        15.0
    }
    var fontProvider: FontProvider {
        .sfPro(weight: .semiBold)
    }
}
