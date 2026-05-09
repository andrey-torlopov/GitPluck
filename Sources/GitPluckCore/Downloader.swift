import Foundation

public struct DownloadReport: Sendable {
    public let outputDirectory: URL
    public let downloaded: [String]
    public let errors: [String]

    public init(outputDirectory: URL, downloaded: [String], errors: [String]) {
        self.outputDirectory = outputDirectory
        self.downloaded = downloaded
        self.errors = errors
    }
}

public final class Downloader: @unchecked Sendable {
    private let client: GitHubClient
    private let repository: LoadedRepository
    private let outputDirectory: URL
    private let fileManager: FileManager

    public init(client: GitHubClient, repository: LoadedRepository, outputDirectory: URL, fileManager: FileManager = .default) {
        self.client = client
        self.repository = repository
        self.outputDirectory = outputDirectory
        self.fileManager = fileManager
    }

    public func download(_ files: [DownloadFile], progress: (String) -> Void) async throws -> DownloadReport {
        try fileManager.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

        var downloaded: [String] = []
        var errors: [String] = []

        for file in files {
            do {
                try await download(file, progress: progress)
                downloaded.append(file.relativePath)
            } catch {
                errors.append("\(file.relativePath): \(error.localizedDescription)")
            }
        }

        return DownloadReport(outputDirectory: outputDirectory, downloaded: downloaded, errors: errors)
    }

    private func download(_ file: DownloadFile, progress: (String) -> Void) async throws {
        guard let sourceURL = file.item.downloadURL else {
            throw GitPluckError.apiError("Для файла \(file.item.path) отсутствует download URL")
        }

        progress("Скачиваю: \(file.relativePath)")
        var data = try await client.downloadData(from: sourceURL)

        if let pointer = LFSPointer.parse(data: data) {
            progress("Скачиваю LFS: \(file.relativePath)")
            if let lfsURL = try? await client.fetchLFSDownloadURL(
                owner: repository.url.owner,
                repo: repository.url.repo,
                oid: pointer.oid,
                size: pointer.size
            ) {
                data = try await client.downloadData(from: lfsURL)
            } else if let branch = repository.url.branch {
                let fallbackURL = client.mediaURL(
                    owner: repository.url.owner,
                    repo: repository.url.repo,
                    branch: branch,
                    path: file.item.path
                )
                data = try await client.downloadData(from: fallbackURL)
            }
        }

        let destination = outputDirectory.appendingPathComponent(file.relativePath, isDirectory: false)
        let parent = destination.deletingLastPathComponent()
        try fileManager.createDirectory(at: parent, withIntermediateDirectories: true)
        try data.write(to: destination, options: .atomic)
    }
}
