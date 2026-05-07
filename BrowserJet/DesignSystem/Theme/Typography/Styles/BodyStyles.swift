//
//  BodyStyles.swift
//  browserjet-wkwebview
//
//  Created by Moiz Ul Hasan on 10/02/2026.
//

import Foundation

struct TextBody1: Typography {
    var size: CGFloat {
        16.0
    }
    var fontProvider: FontProvider {
        .sfPro(weight: .regular)
    }
}

struct TextBody2: Typography {
    var size: CGFloat {
        12.0
    }
    var fontProvider: FontProvider {
        .sfPro(weight: .regular)
    }
}

struct TextCaption: Typography {
    var size: CGFloat {
        11.0
    }
    var fontProvider: FontProvider {
        .sfPro(weight: .regular)
    }
}
