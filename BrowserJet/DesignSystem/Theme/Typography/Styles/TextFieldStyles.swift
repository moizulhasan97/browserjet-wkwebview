//
//  TextFieldStyles.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 11/02/2026.
//

import Foundation

struct LauncherField: Typography {
    var size: CGFloat {
        16.0
    }
    var fontProvider: FontProvider {
        .sfPro(weight: .light)
    }
}

struct ActivationField: Typography {
    var size: CGFloat {
        14.0
    }
    var fontProvider: FontProvider {
        .sfPro(weight: .regular)
    }
}
