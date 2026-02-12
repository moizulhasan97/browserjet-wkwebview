//
//  ViewConfig.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 12/02/2026.
//

import Foundation

protocol ViewConfig {
    var viewCornerRadius : CGFloat { get }
    var textFieldCornerRadius: CGFloat { get }
    var buttonCornerRadius: CornerRadius { get }
}
