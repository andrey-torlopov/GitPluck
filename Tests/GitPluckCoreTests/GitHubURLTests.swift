import Testing
@testable import GitPluckCore

@Test func parsesRepositoryRootURL() throws {
    let parsed = try GitHubURL.parse("https://github.com/rust-lang/rust")

    #expect(parsed.owner == "rust-lang")
    #expect(parsed.repo == "rust")
    #expect(parsed.branch == nil)
    #expect(parsed.path == "")
}

@Test func parsesTreeURL() throws {
    let parsed = try GitHubURL.parse("https://github.com/rust-lang/rust/tree/master/src/tools")

    #expect(parsed.owner == "rust-lang")
    #expect(parsed.repo == "rust")
    #expect(parsed.branch == "master")
    #expect(parsed.path == "src/tools")
}

@Test func parsesBlobURL() throws {
    let parsed = try GitHubURL.parse("https://github.com/apple/swift/blob/main/README.md")

    #expect(parsed.owner == "apple")
    #expect(parsed.repo == "swift")
    #expect(parsed.branch == "main")
    #expect(parsed.path == "README.md")
}

@Test func parsesOwnerRepoShorthand() throws {
    let parsed = try GitHubURL.parse("apple/swift")

    #expect(parsed.owner == "apple")
    #expect(parsed.repo == "swift")
    #expect(parsed.branch == nil)
    #expect(parsed.path == "")
}

@Test func rejectsNonGithubURL() throws {
    #expect(throws: GitPluckError.notGitHubURL) {
        try GitHubURL.parse("https://example.com/apple/swift")
    }
}
