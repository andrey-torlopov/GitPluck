import Foundation

public final class GitHubClient: @unchecked Sendable {
    private let token: String?
    private let session: URLSession
    private let decoder: JSONDecoder

    public init(token: String? = nil, session: URLSession = .shared) {
        self.token = token?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        self.session = session
        self.decoder = JSONDecoder()
    }

    public func loadRepositoryTree(from input: GitHubURL) async throws -> LoadedRepository {
        var resolved = input

        if resolved.branch == nil {
            let defaultBranch = try await fetchDefaultBranch(owner: resolved.owner, repo: resolved.repo)
            resolved = resolved.resolved(branch: defaultBranch)
        }

        do {
            return try await fetchTree(for: resolved)
        } catch GitPluckError.notFound where input.branch == nil || input.branch == "main" {
            let defaultBranch = try await fetchDefaultBranch(owner: resolved.owner, repo: resolved.repo)
            let fallback = resolved.resolved(branch: defaultBranch)
            return try await fetchTree(for: fallback)
        }
    }

    public func downloadData(from url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        applyDefaultHeaders(to: &request, accept: "*/*")
        return try await send(request)
    }

    public func fetchPreview(from url: URL, maxBytes: Int = 16 * 1024) async throws -> Data {
        var request = URLRequest(url: url)
        applyDefaultHeaders(to: &request, accept: "*/*")
        request.setValue("bytes=0-\(max(0, maxBytes - 1))", forHTTPHeaderField: "Range")
        return try await send(request, allowPartialContent: true)
    }

    public func fetchLFSDownloadURL(owner: String, repo: String, oid: String, size: Int64) async throws -> URL {
        let url = URL(string: "https://github.com/\(percentEncodePathSegment(owner))/\(percentEncodePathSegment(repo)).git/info/lfs/objects/batch")!
        let body: [String: Any] = [
            "operation": "download",
            "transfers": ["basic"],
            "objects": [
                [
                    "oid": oid,
                    "size": size
                ]
            ]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        applyDefaultHeaders(to: &request, accept: "application/vnd.git-lfs+json")
        request.setValue("application/vnd.git-lfs+json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let data = try await send(request)
        let response = try decoder.decode(LFSBatchResponse.self, from: data)

        guard let href = response.objects.first?.actions?.download?.href,
              let downloadURL = URL(string: href) else {
            throw GitPluckError.apiError("LFS download URL отсутствует в ответе GitHub")
        }

        return downloadURL
    }

    public func mediaURL(owner: String, repo: String, branch: String, path: String) -> URL {
        buildURL(host: "media.githubusercontent.com", pathSegments: ["media", owner, repo, branch] + pathSegments(path))
    }

    private func fetchDefaultBranch(owner: String, repo: String) async throws -> String {
        let url = buildURL(host: "api.github.com", pathSegments: ["repos", owner, repo])
        var request = URLRequest(url: url)
        applyDefaultHeaders(to: &request)

        let data = try await send(request)
        let info = try decoder.decode(RepositoryInfoResponse.self, from: data)
        return info.defaultBranch
    }

    private func fetchTree(for url: GitHubURL) async throws -> LoadedRepository {
        guard let branch = url.branch else {
            throw GitPluckError.apiError("Не удалось определить ветку репозитория")
        }

        let treeURL = buildURL(
            host: "api.github.com",
            pathSegments: ["repos", url.owner, url.repo, "git", "trees", branch],
            queryItems: [URLQueryItem(name: "recursive", value: "1")]
        )
        var request = URLRequest(url: treeURL)
        applyDefaultHeaders(to: &request)

        let data = try await send(request)
        let response = try decoder.decode(GitTreeResponse.self, from: data)
        let allItems = response.tree.map { entry in
            mapTreeEntry(entry, owner: url.owner, repo: url.repo, branch: branch)
        }

        let scopedItems = scope(items: allItems, to: url.path)
        if !url.path.isEmpty, scopedItems.isEmpty {
            throw GitPluckError.notFound(url.path)
        }

        return LoadedRepository(url: url, items: scopedItems, truncated: response.truncated)
    }

    private func scope(items: [RepoItem], to path: String) -> [RepoItem] {
        let normalizedPath = GitHubURL.normalizePath(path)
        guard !normalizedPath.isEmpty else {
            return items
        }

        let prefix = normalizedPath + "/"
        return items.filter { item in
            item.path == normalizedPath || item.path.hasPrefix(prefix)
        }
    }

    private func mapTreeEntry(_ entry: GitTreeEntry, owner: String, repo: String, branch: String) -> RepoItem {
        let kind: RepoItemKind = entry.type == "tree" ? .directory : .file
        let name = entry.path.split(separator: "/").last.map(String.init) ?? entry.path
        let downloadURL = kind == .file
            ? buildURL(host: "raw.githubusercontent.com", pathSegments: [owner, repo, branch] + pathSegments(entry.path))
            : nil

        return RepoItem(
            name: name,
            path: GitHubURL.normalizePath(entry.path),
            kind: kind,
            size: entry.size,
            downloadURL: downloadURL
        )
    }

    private func applyDefaultHeaders(to request: inout URLRequest, accept: String = "application/vnd.github+json") {
        request.setValue("GitPluck/0.1", forHTTPHeaderField: "User-Agent")
        request.setValue(accept, forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")

        if let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
    }

    private func send(_ request: URLRequest, allowPartialContent: Bool = false) async throws -> Data {
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GitPluckError.invalidHTTPResponse
        }

        let statusCode = httpResponse.statusCode
        if (200...299).contains(statusCode) || allowPartialContent && statusCode == 206 {
            return data
        }

        switch statusCode {
        case 401:
            throw GitPluckError.invalidToken
        case 403:
            let remaining = httpResponse.value(forHTTPHeaderField: "X-RateLimit-Remaining")
                .flatMap(Int.init) ?? 1
            if remaining == 0 {
                throw GitPluckError.rateLimitExceeded(token == nil ? "anonymous API" : "authenticated API")
            }
            throw GitPluckError.apiError(responseMessage(from: data, fallback: "HTTP 403 Forbidden"))
        case 404:
            throw GitPluckError.notFound(request.url?.absoluteString ?? "unknown")
        default:
            throw GitPluckError.apiError(responseMessage(from: data, fallback: "HTTP \(statusCode)"))
        }
    }

    private func responseMessage(from data: Data, fallback: String) -> String {
        if let decoded = try? decoder.decode(GitHubErrorResponse.self, from: data) {
            return decoded.message
        }
        if let text = String(data: data, encoding: .utf8), !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return text.prefix(500).description
        }
        return fallback
    }
}

private struct RepositoryInfoResponse: Decodable {
    let defaultBranch: String

    private enum CodingKeys: String, CodingKey {
        case defaultBranch = "default_branch"
    }
}

private struct GitTreeResponse: Decodable {
    let tree: [GitTreeEntry]
    let truncated: Bool
}

private struct GitTreeEntry: Decodable {
    let path: String
    let type: String
    let size: Int64?
}

private struct GitHubErrorResponse: Decodable {
    let message: String
}

private struct LFSBatchResponse: Decodable {
    let objects: [LFSObject]
}

private struct LFSObject: Decodable {
    let actions: LFSActions?
}

private struct LFSActions: Decodable {
    let download: LFSDownloadAction?
}

private struct LFSDownloadAction: Decodable {
    let href: String
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}

func buildURL(host: String, pathSegments segments: [String], queryItems: [URLQueryItem] = []) -> URL {
    var components = URLComponents()
    components.scheme = "https"
    components.host = host
    components.percentEncodedPath = "/" + segments
        .map(percentEncodePathSegment)
        .joined(separator: "/")
    components.queryItems = queryItems.isEmpty ? nil : queryItems
    return components.url!
}

func pathSegments(_ path: String) -> [String] {
    GitHubURL.normalizePath(path)
        .split(separator: "/", omittingEmptySubsequences: true)
        .map(String.init)
}

func percentEncodePathSegment(_ value: String) -> String {
    var allowed = CharacterSet.urlPathAllowed
    allowed.remove(charactersIn: "/?#[]@!$&'()*+,;=")
    return value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
}
