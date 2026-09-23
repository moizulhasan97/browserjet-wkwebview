//
//  VPNProvider.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 19/02/2026.
//

import Foundation

/// Supplies proxy pool definitions for built-in VPN tiers (Remote Config in the app, a stub in tests).
@MainActor
protocol ProxyPoolTemplateProviding {
    func proxyPoolTemplate(forVPNID vpnID: String) -> ProxyPoolTemplate?
}

/// Resolves built-in VPN tiers into per-window proxy providers and reports whether a tier is usable right now.
@MainActor
final class VPNProvider {
    private let configurations: [VPNConfiguration]
    private let templateProvider: ProxyPoolTemplateProviding

    init(configurations: [VPNConfiguration], templateProvider: ProxyPoolTemplateProviding) {
        self.configurations = configurations
        self.templateProvider = templateProvider
    }

    /// `false` when the tier is unknown, or its Remote Config pool is missing or invalid.
    func isAvailable(_ vpn: VPNType) -> Bool {
        guard let config = configuration(for: vpn) else { return false }

        switch config.layout {
        case .remoteConfigPool:
            return templateProvider.proxyPoolTemplate(forVPNID: config.id) != nil
        case .multiSlotZip:
            return true
        }
    }

    /// Builds a fresh provider per browser window, so session ids and rotation state are never shared between windows.
    func makeProxyProvider(for vpn: VPNType, region: RegionType) -> AuthProxyProviding? {
        guard let config = configuration(for: vpn) else {
            AppLogger.warning("VPNProvider: no configuration for \(vpn.rawValue)")
            return nil
        }

        switch config.layout {
        case .remoteConfigPool:
            guard let template = templateProvider.proxyPoolTemplate(forVPNID: config.id) else {
                AppLogger.warning("VPNProvider: Remote Config has no usable pool for \(config.id)")
                return nil
            }
            return TemplatedAuthProxyProvider(template: template, region: region)

        case let .multiSlotZip(password, portGen, ipGen, usernameStrategy):
            let proxies = generateZippedProxies(
                password: password,
                portGenerationConfig: portGen,
                ipGenerationConfig: ipGen,
                usernameStrategy: usernameStrategy
            )
            return proxies.isEmpty ? nil : ListAuthProxyProvider(proxies: proxies)
        }
    }

    private func configuration(for vpn: VPNType) -> VPNConfiguration? {
        configurations.first { $0.id == vpn.rawValue }
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
            let (ipAddress, port) = tuple
            return AuthProxy(
                host: ipAddress,
                port: port,
                username: usernameGenerator.generateUsername(for: index),
                password: password
            )
        }
    }

    private func generateIPs(from config: IPGenerationConfig) -> [String] {
        switch config.ipPattern {
        case let .sequential(baseIP, startIndex):
            return (0..<config.count).map { index in
                incrementIP(baseIP, by: startIndex + index)
            }
        case let .custom(ips):
            return ips
        }
    }

    private func generatePorts(from config: PortGenerationConfig) -> [UInt16] {
        switch config.portPattern {
        case let .static(port):
            return Array(repeating: port, count: config.count)
        case let .sequential(basePort, startIndex):
            return (0..<config.count).map { index in
                UInt16(Int(basePort) + startIndex + index)
            }
        case let .custom(ports):
            return ports
        }
    }

    private func makeUsernameGenerator(from strategy: UsernameGenerationStrategy) -> UsernameGenerator {
        switch strategy {
        case let .static(username):
            return StaticUsernameGenerator(username: username)
        case let .sequential(base, startIndex):
            return SequentialUsernameGenerator(base: base, startIndex: startIndex)
        case let .custom(generator):
            return CustomUsernameGenerator(generator: generator)
        }
    }

    private func incrementIP(_ ipAddress: String, by amount: Int) -> String {
        let components = ipAddress.split(separator: ".").compactMap { Int($0) }
        guard components.count == 4 else { return ipAddress }

        let lastOctet = components[3] + amount
        guard lastOctet <= 255 else { return ipAddress }

        return "\(components[0]).\(components[1]).\(components[2]).\(lastOctet)"
    }
}
