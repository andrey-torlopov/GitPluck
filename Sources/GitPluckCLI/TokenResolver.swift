import Foundation

enum TokenResolver {
    static func resolve(cliToken: String?) throws -> String? {
        if let token = normalize(cliToken) {
            if isAutoToken(token) {
                return try ghToken(strict: true)
            }
            return token
        }

        for key in ["GHGRAB_GITHUB_TOKEN", "GITHUB_TOKEN"] {
            guard let token = normalize(ProcessInfo.processInfo.environment[key]) else {
                continue
            }
            if isAutoToken(token) {
                if let resolved = try ghToken(strict: false) {
                    return resolved
                }
                continue
            }
            return token
        }

        return try ghToken(strict: false)
    }

    private static func normalize(_ value: String?) -> String? {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func isAutoToken(_ value: String) -> Bool {
        value.caseInsensitiveCompare("auto") == .orderedSame
            || value.caseInsensitiveCompare("gh") == .orderedSame
    }

    private static func ghToken(strict: Bool) throws -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["gh", "auth", "token"]

        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            if strict {
                throw CLIError.unexpectedArgument("Не удалось выполнить `gh auth token`: \(error.localizedDescription)")
            }
            return nil
        }

        guard process.terminationStatus == 0 else {
            if strict {
                let message = String(data: stderr.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                throw CLIError.unexpectedArgument("`gh auth token` завершился с ошибкой: \(message ?? "без деталей")")
            }
            return nil
        }

        let output = String(data: stdout.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        var seen = Set<String>()
        let tokens = output
            .split(separator: "\n")
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .filter { seen.insert($0).inserted }

        return tokens.first
    }
}
