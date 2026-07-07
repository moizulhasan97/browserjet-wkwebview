//
//  ProxyImportExportParser.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 07/07/2026.
//

enum ProxyImportExportParser {
    
    // MARK: - Import
    static func parseImport(
        fileContents: String,
        existingProxiesInGroup: [ManagedProxy]
    ) -> (drafts: [ManagedProxyDraft], summary: ProxyImportSummary) {
        let lines = fileContents
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        var accepted: [ManagedProxyDraft] = []
        var seenKeys = Set(existingProxiesInGroup.map {
            "\($0.host):\($0.port):\($0.username):\($0.password)"
        })
        var invalidSamples: [String] = []
        var skippedDuplicateCount = 0
        var invalidCount = 0
        
        for line in lines {
            switch parseLine(line) {
            case .success(let draft):
                if seenKeys.contains(draft.duplicateKey) {
                    skippedDuplicateCount += 1
                } else {
                    seenKeys.insert(draft.duplicateKey)
                    accepted.append(draft)
                }
            case .failure:
                invalidCount += 1
                if invalidSamples.count < 5 {
                    invalidSamples.append(line)
                }
            }
        }
        
        let summary = ProxyImportSummary(
            addedCount: accepted.count,
            skippedDuplicateCount: skippedDuplicateCount,
            invalidCount: invalidCount,
            invalidSamples: invalidSamples
        )
        
        return (accepted, summary)
    }
    
    /// Parses a single line in either `IP,PORT,USER,PASS` or `IP:PORT:USER:PASS` form.
    static func parseLine(_ raw: String) -> Result<ManagedProxyDraft, ManagedProxyError> {
        let separator: Character = raw.contains(",") ? "," : ":"
        let parts = raw
            .split(separator: separator, omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespaces) }
        
        guard parts.count == 4 else { return .failure(.invalidHost) }
        
        return ManagedProxyValidator.validateProxyFields(
            host: parts[0],
            port: parts[1],
            username: parts[2],
            password: parts[3]
        )
    }
    
    // MARK: - Export
    
    /// `IP,PORT,USERNAME,PASSWORD` — one line per proxy, per spec.
    static func exportCSV(_ proxies: [ManagedProxy]) -> String {
        proxies
            .map { "\($0.host),\($0.port),\($0.username),\($0.password)" }
            .joined(separator: "\n")
    }
}
