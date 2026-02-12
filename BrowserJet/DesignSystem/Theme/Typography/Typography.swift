//
//  Typography.swift
//  browserjet-wkwebview
//
//  Created by Moiz Ul Hasan on 10/02/2026.
//

import SwiftUI

protocol Typography {
    var size: CGFloat { get }
    var fontProvider: FontProvider { get }
}

extension Typography {
    var font: Font {
        fontProvider.font(size: size)
    }
}
