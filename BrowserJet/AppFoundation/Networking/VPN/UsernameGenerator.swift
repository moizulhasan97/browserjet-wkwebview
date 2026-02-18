//
//  UsernameGenerator.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 19/02/2026.
//

protocol UsernameGenerator {
    func generateUsername(for index: Int) -> String
}

struct StaticUsernameGenerator: UsernameGenerator {
    let username: String
    
    func generateUsername(for index: Int) -> String {
        username
    }
}

struct SequentialUsernameGenerator: UsernameGenerator {
    let base: String
    let startIndex: Int
    
    func generateUsername(for index: Int) -> String {
        return base
    }
}

struct CustomUsernameGenerator: UsernameGenerator {
    let generator: (Int) -> String
    
    func generateUsername(for index: Int) -> String {
        generator(index)
    }
}
