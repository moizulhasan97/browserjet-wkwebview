//
//  DatatudePoolConfig.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 29/04/2026.
//

import Foundation

struct DatatudePoolConfig: Hashable {
    let host: String
    let port: UInt16
    let password: String
    /// Inclusive range for the numeric suffix `11...99_999`.
    let counterRange: ClosedRange<Int>
    /// datatude-{region}-numXXXXXXXX -> the number of X count
    /// 00000011, 00099999
    let counterDigitWidth: Int
    
    init(
        host: String,
        port: UInt16,
        password: String,
        counterRange: ClosedRange<Int> = 11...99_999,
        counterDigitWidth: Int = 8
    ) {
        self.host = host
        self.port = port
        self.password = password
        self.counterRange = counterRange
        self.counterDigitWidth = counterDigitWidth
    }
}
