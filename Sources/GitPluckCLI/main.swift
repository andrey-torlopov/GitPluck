import Foundation
import Darwin
import GitPluckCore

enum GitPluckCLI {
    static func run() async throws {
        let options = try CommandOptions.parse(Array(CommandLine.arguments.dropFirst()))

        if options.showHelp {
            print(HelpText.main)
            return
        }

        let input = try options.url ?? promptForURL()
        let token = try TokenResolver.resolve(cliToken: options.token)
        let client = GitHubClient(token: token)
        let parsedURL = try GitHubURL.parse(input)

        print("Загружаю дерево \(parsedURL.repoFullName)...")
        let repository = try await client.loadRepositoryTree(from: parsedURL)
        print("Готово: \(repository.items.count) элементов.")

        let browser = ConsoleBrowser(repository: repository, client: client)
        guard let selectedPaths = try await browser.run() else {
            print("Отменено.")
            return
        }

        let files = try SelectionResolver.resolve(selectedPaths: selectedPaths, in: repository.items)
        let outputDirectory = try resolveOutputDirectory(options: options, repository: repository)

        print("Скачиваю файлов: \(files.count)")
        let downloader = Downloader(client: client, repository: repository, outputDirectory: outputDirectory)
        let report = try await downloader.download(files) { message in
            print(message)
        }

        print("\nГотово.")
        print("Папка: \(report.outputDirectory.path)")
        print("Скачано: \(report.downloaded.count)")

        if !report.errors.isEmpty {
            print("Ошибки: \(report.errors.count)")
            for error in report.errors {
                print("  - \(error)")
            }
            exit(2)
        }
    }

    private static func promptForURL() throws -> String {
        print("GitHub URL: ", terminator: "")
        guard let input = readLine(strippingNewline: true)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
            !input.isEmpty else {
            throw CLIError.emptyURL
        }
        return input
    }

    private static func resolveOutputDirectory(options: CommandOptions, repository: LoadedRepository) throws -> URL {
        let fileManager = FileManager.default
        let baseURL: URL

        if options.cwd {
            baseURL = URL(fileURLWithPath: fileManager.currentDirectoryPath, isDirectory: true)
        } else if let outputPath = options.outputPath {
            baseURL = expandTilde(outputPath)
        } else if let downloads = fileManager.urls(for: .downloadsDirectory, in: .userDomainMask).first {
            baseURL = downloads
        } else if let home = fileManager.homeDirectoryForCurrentUser as URL? {
            baseURL = home.appendingPathComponent("Downloads", isDirectory: true)
        } else {
            throw GitPluckError.outputPathError("не удалось определить Downloads")
        }

        return options.noFolder
            ? baseURL
            : baseURL.appendingPathComponent(repository.url.repo, isDirectory: true)
    }

    private static func expandTilde(_ path: String) -> URL {
        if path == "~" {
            return FileManager.default.homeDirectoryForCurrentUser
        }

        if path.hasPrefix("~/") {
            let suffix = String(path.dropFirst(2))
            return FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(suffix, isDirectory: true)
        }

        return URL(fileURLWithPath: path, isDirectory: true)
    }
}

do {
    try await GitPluckCLI.run()
} catch {
    fputs("Ошибка: \(error.localizedDescription)\n", stderr)
    exit(1)
}
