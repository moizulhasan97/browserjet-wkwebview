//
//  VPNProvider.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 19/02/2026.
//

import Foundation

final class VPNProvider {
    private let configurations: [VPNConfiguration]
    
    init(configurations: [VPNConfiguration]) {
        self.configurations = configurations
    }
    
    func generateProxies(for vpnID: String, region: RegionType?) -> [AuthProxy] {
        guard let config = configurations.first(where: { $0.id == vpnID }) else {
            return []
        }
        
        switch config.layout {
        case .remoteManaged:
            // coming from API
            return []
            
        case .datatude(let pool):
            guard let region else { return [] }
            return Self.makeDatatudeProxies(config: pool, region: region)
            
        case .multiSlotZip(let password, let portGen, let ipGen, let usernameStrategy):
            return generateZippedProxies(
                password: password,
                portGenerationConfig: portGen,
                ipGenerationConfig: ipGen,
                usernameStrategy: usernameStrategy
            )
        }
    }
    
    private static func makeDatatudeProxies(config: DatatudePoolConfig, region: RegionType) -> [AuthProxy] {
        let slug = region.datatudeRegionSlug
        let format = "%0\(config.counterDigitWidth)d"
        var out: [AuthProxy] = []
        let capacity = config.counterRange.count
        if capacity > 0 {
            out.reserveCapacity(Swift.min(capacity, 100_000))
        }
        for index in stride(from: config.counterRange.lowerBound, through: config.counterRange.upperBound, by: 1) {
            let suffix = String(format: format, locale: nil, index)
            let username = "datatude-\(slug)-num\(suffix)"
            out.append(
                AuthProxy(
                    host: config.host,
                    port: config.port,
                    username: username,
                    password: config.password
                )
            )
        }
        return out
    }
    
    private func generateZippedProxies(
        password: String,
        portGenerationConfig: PortGenerationConfig,
        ipGenerationConfig: IPGenerationConfig,
        usernameStrategy: UsernameGenerationStrategy
    ) -> [AuthProxy] {
        let ips = generateIPs(from: ipGenerationConfig)
        let ports = generatePorts(from: portGenerationConfig)
        let usernameGenerator = makeUsernameGenerator(from: usernameStrategy)
        
        return zip(ips, ports).enumerated().map { index, tuple in
            let (ip, port) = tuple
            return AuthProxy(
                host: ip,
                port: port,
                username: usernameGenerator.generateUsername(for: index),
                password: password
            )
        }
    }
    
    private func generateIPs(from config: IPGenerationConfig) -> [String] {
        switch config.ipPattern {
        case .sequential(let baseIP, let startIndex):
            return (0..<config.count).map { index in
                incrementIP(baseIP, by: startIndex + index)
            }
        case .custom(let ips):
            return ips
        }
    }
    
    private func generatePorts(from config: PortGenerationConfig) -> [UInt16] {
        switch config.portPattern {
        case .static(let port):
            return Array(repeating: port, count: config.count)
        case .sequential(let basePort, let startIndex):
            return (0..<config.count).map { index in
                UInt16(Int(basePort) + startIndex + index)
            }
        case .custom(let ports):
            return ports
        }
    }
    
    private func makeUsernameGenerator(from strategy: UsernameGenerationStrategy) -> UsernameGenerator {
        switch strategy {
        case .static(let username):
            return StaticUsernameGenerator(username: username)
        case .sequential(let base, let startIndex):
            return SequentialUsernameGenerator(base: base, startIndex: startIndex)
        case .custom(let generator):
            return CustomUsernameGenerator(generator: generator)
        }
    }
    
    private func incrementIP(_ ip: String, by amount: Int) -> String {
        let components = ip.split(separator: ".").compactMap { Int($0) }
        guard components.count == 4 else { return ip }
        
        let lastOctet = components[3] + amount
        guard lastOctet <= 255 else { return ip }
        
        return "\(components[0]).\(components[1]).\(components[2]).\(lastOctet)"
    }
}
