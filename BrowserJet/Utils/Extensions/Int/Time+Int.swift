//
//  Time+Int.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 05/05/2026.
//

extension Int {
    var seconds: UInt64 {
        UInt64(self) * 1_000_000_000
    }
    
    var minutes: UInt64 {
        UInt64(self) * 60 * 1_000_000_000
    }
}
