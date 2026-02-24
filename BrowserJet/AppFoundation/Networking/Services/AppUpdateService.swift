//
//  AppUpdateService.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 24/02/2026.
//
import Foundation

final class AppUpdateService {
    private let client: APIClient

    init(client: APIClient = .shared) {
        self.client = client
    }

    func latestVersion() async throws -> String {
        AppLogger.info("AppUpdateService: checking latest Mac version")
        do {
            let version = try await client.requestText(AppUpdateEndpoint.latestVersion)
            AppLogger.info("AppUpdateService: latest version is '\(version)'")
            return version
        } catch {
            AppLogger.error("AppUpdateService: latestVersion failed - \(error.localizedDescription)")
            throw error
        }
    }
}
