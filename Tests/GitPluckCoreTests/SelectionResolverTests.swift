import Foundation
import Testing
@testable import GitPluckCore

@Test func resolvesSingleFileSelection() throws {
    let items = [
        file("src/main.swift"),
        file("README.md")
    ]

    let selected = try SelectionResolver.resolve(
        selectedPaths: ["src/main.swift"],
        in: items
    )

    #expect(selected.map(\.relativePath) == ["src/main.swift"])
}

@Test func resolvesDirectorySelectionToNestedFiles() throws {
    let items = [
        directory("src"),
        file("src/main.swift"),
        file("src/lib.swift"),
        file("README.md")
    ]

    let selected = try SelectionResolver.resolve(selectedPaths: ["src"], in: items)

    #expect(selected.map(\.relativePath) == ["src/lib.swift", "src/main.swift"])
}

@Test func deduplicatesNestedSelections() throws {
    let items = [
        directory("src"),
        file("src/main.swift"),
        file("src/lib.swift")
    ]

    let selected = try SelectionResolver.resolve(
        selectedPaths: ["src", "src/main.swift"],
        in: items
    )

    #expect(selected.map(\.relativePath) == ["src/lib.swift", "src/main.swift"])
}

@Test func rejectsMissingPath() throws {
    #expect(throws: GitPluckError.pathNotFound("docs")) {
        try SelectionResolver.resolve(selectedPaths: ["docs"], in: [file("README.md")])
    }
}

@Test func calculatesFolderSizesUsingAllNestedFiles() {
    let items = [
        directory("src"),
        directory("src/App"),
        file("src/App/main.swift", size: 100),
        file("src/App/view.swift", size: 50),
        file("src/lib.swift", size: 25)
    ]

    let sizes = SelectionResolver.folderSizes(for: items)

    #expect(sizes["src"] == 175)
    #expect(sizes["src/App"] == 150)
}

private func file(_ path: String, size: Int64 = 10) -> RepoItem {
    RepoItem(
        name: path.split(separator: "/").last.map(String.init) ?? path,
        path: path,
        kind: .file,
        size: size,
        downloadURL: URL(string: "https://example.com/\(path)")
    )
}

private func directory(_ path: String) -> RepoItem {
    RepoItem(
        name: path.split(separator: "/").last.map(String.init) ?? path,
        path: path,
        kind: .directory,
        size: nil,
        downloadURL: nil
    )
}
