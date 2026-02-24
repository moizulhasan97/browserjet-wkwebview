//
//  AppUpdateService.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 24/02/2026.
//


final class AppUpdateService {
    private let client: APIClient

    init(client: APIClient = .shared) {
        self.client = client
    }

    func latestVersion() async throws -> String {
        try await client.requestText(AppUpdateEndpoint.latestVersion)
    }
}
