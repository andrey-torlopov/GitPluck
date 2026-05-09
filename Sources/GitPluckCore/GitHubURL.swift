import Foundation

public struct GitHubURL: Equatable, Sendable {
    public let owner: String
    public let repo: String
    public var branch: String?
    public let path: String

    public init(owner: String, repo: String, branch: String?, path: String) {
        self.owner = owner
        self.repo = repo
        self.branch = branch
        self.path = GitHubURL.normalizePath(path)
    }

    public static func parse(_ rawValue: String) throws -> GitHubURL {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw GitPluckError.invalidURL(rawValue)
        }

        if !trimmed.lowercased().hasPrefix("http://"),
           !trimmed.lowercased().hasPrefix("https://"),
           trimmed.split(separator: "/").count >= 2 {
            return try parsePathOnly(trimmed)
        }

        guard let url = URL(string: trimmed), let host = url.host(percentEncoded: false) else {
            throw GitPluckError.invalidURL(rawValue)
        }

        guard host.lowercased() == "github.com" else {
            throw GitPluckError.notGitHubURL
        }

        let segments = url.path
            .split(separator: "/", omittingEmptySubsequences: true)
            .map { String($0).removingPercentEncoding ?? String($0) }

        return try parseSegments(segments)
    }

    public func resolved(branch: String) -> GitHubURL {
        GitHubURL(owner: owner, repo: repo, branch: branch, path: path)
    }

    public var repoFullName: String {
        "\(owner)/\(repo)"
    }

    public static func normalizePath(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\", with: "/")
            .split(separator: "/", omittingEmptySubsequences: true)
            .joined(separator: "/")
    }

    private static func parsePathOnly(_ value: String) throws -> GitHubURL {
        let segments = value
            .split(separator: "/", omittingEmptySubsequences: true)
            .map(String.init)

        return try parseSegments(segments)
    }

    private static func parseSegments(_ segments: [String]) throws -> GitHubURL {
        guard segments.count >= 2 else {
            throw GitPluckError.missingOwnerOrRepository
        }

        let owner = segments[0]
        var repo = segments[1]
        if repo.hasSuffix(".git") {
            repo.removeLast(4)
        }

        guard !owner.isEmpty, !repo.isEmpty else {
            throw GitPluckError.missingOwnerOrRepository
        }

        if segments.count >= 4, segments[2] == "tree" || segments[2] == "blob" {
            let branch = segments[3]
            let path = segments.count > 4 ? segments.dropFirst(4).joined(separator: "/") : ""
            return GitHubURL(owner: owner, repo: repo, branch: branch, path: path)
        }

        return GitHubURL(owner: owner, repo: repo, branch: nil, path: "")
    }
}
