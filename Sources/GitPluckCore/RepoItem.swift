import Foundation

public enum RepoItemKind: String, Sendable {
    case file
    case directory
}

public struct RepoItem: Equatable, Hashable, Sendable {
    public let name: String
    public let path: String
    public let kind: RepoItemKind
    public let size: Int64?
    public let downloadURL: URL?

    public init(name: String, path: String, kind: RepoItemKind, size: Int64?, downloadURL: URL?) {
        self.name = name
        self.path = path
        self.kind = kind
        self.size = size
        self.downloadURL = downloadURL
    }

    public var isFile: Bool {
        kind == .file
    }

    public var isDirectory: Bool {
        kind == .directory
    }
}

public struct LoadedRepository: Sendable {
    public let url: GitHubURL
    public let items: [RepoItem]
    public let truncated: Bool

    public init(url: GitHubURL, items: [RepoItem], truncated: Bool) {
        self.url = url
        self.items = items
        self.truncated = truncated
    }
}

public struct DownloadFile: Equatable, Sendable {
    public let item: RepoItem
    public let relativePath: String

    public init(item: RepoItem, relativePath: String) {
        self.item = item
        self.relativePath = GitHubURL.normalizePath(relativePath)
    }
}
