//
//  PaymentAlertItem.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 25/03/2026.
//

import Foundation

struct PaymentAlertItem: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let url: URL
}
