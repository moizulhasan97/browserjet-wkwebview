//
//  VPNProvider.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 19/02/2026.
//


final class VPNProvider {
    private let configurations: [VPNConfiguration]
    
    init(configurations: [VPNConfiguration]) {
        self.configurations = configurations
    }
    
    /// Generate all AuthProxy instances for a given VPN
    func generateProxies(for vpnID: String) -> [AuthProxy] {
        guard let config = configurations.first(where: { $0.id == vpnID }) else {
            return []
        }
        
        return generateProxies(from: config)
    }
    
    private func generateProxies(from config: VPNConfiguration) -> [AuthProxy] {
        let ips = generateIPs(from: config.ipGenerationConfig)
        let ports = generatePorts(from: config.portGenerationConfig)
        let usernameGenerator = makeUsernameGenerator(from: config.usernameStrategy)
        
        return zip(ips, ports).enumerated().map { index, tuple in
            let (ip, port) = tuple
            return AuthProxy(
                host: ip,
                port: port,
                username: usernameGenerator.generateUsername(for: index),
                password: config.password
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
        guard components.count == 4 else {
            return ip // Return original if invalid format
        }
        
        let lastOctet = components[3] + amount
        guard lastOctet <= 255 else {
            return ip // Return original if overflow (or handle differently)
        }
        
        return "\(components[0]).\(components[1]).\(components[2]).\(lastOctet)"
    }
}
