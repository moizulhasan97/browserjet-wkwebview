//
//  ProxyConfigurationFactory.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 16/02/2026.
//

import Foundation
import Network
import WebKit

enum ProxyConfigurationFactory {
    static func makeProxyConfiguration(_ proxy: AuthProxy) -> ProxyConfiguration {
        let endpoint = NWEndpoint.hostPort(
            host: .init(proxy.host),
            port: .init(integerLiteral: proxy.port)
        )

        var config = ProxyConfiguration(
            httpCONNECTProxy: endpoint,
            tlsOptions: nil
        )

        config.applyCredential(
            username: proxy.username,
            password: proxy.password
        )

        return config
    }
}
