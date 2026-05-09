import Foundation

public enum SelectionResolver {
    public static func resolve(selectedPaths: Set<String>, in items: [RepoItem]) throws -> [DownloadFile] {
        guard !selectedPaths.isEmpty else {
            throw GitPluckError.emptySelection
        }

        let itemByPath = Dictionary(uniqueKeysWithValues: items.map { ($0.path, $0) })
        var resultByPath: [String: DownloadFile] = [:]

        for selectedPath in selectedPaths.map(GitHubURL.normalizePath).sorted() {
            guard let selectedItem = itemByPath[selectedPath] else {
                throw GitPluckError.pathNotFound(selectedPath)
            }

            if selectedItem.isFile {
                resultByPath[selectedItem.path] = DownloadFile(item: selectedItem, relativePath: selectedItem.path)
                continue
            }

            let prefix = selectedItem.path + "/"
            let nestedFiles = items
                .filter { item in item.isFile && item.path.hasPrefix(prefix) }
                .sorted { $0.path < $1.path }

            guard !nestedFiles.isEmpty else {
                throw GitPluckError.pathNotFound(selectedItem.path)
            }

            for file in nestedFiles {
                resultByPath[file.path] = DownloadFile(item: file, relativePath: file.path)
            }
        }

        return resultByPath.values.sorted { $0.relativePath < $1.relativePath }
    }

    public static func folderSizes(for items: [RepoItem]) -> [String: Int64] {
        var sizes: [String: Int64] = [:]

        for item in items where item.isFile {
            let parts = item.path.split(separator: "/").map(String.init)
            guard parts.count > 1 else {
                continue
            }

            for depth in 1..<parts.count {
                let parent = parts.prefix(depth).joined(separator: "/")
                sizes[parent, default: 0] += item.size ?? 0
            }
        }

        return sizes
    }
}
