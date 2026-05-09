import Foundation
import GitPluckCore

final class ConsoleBrowser {
    private let repository: LoadedRepository
    private let client: GitHubClient
    private let folderSizes: [String: Int64]
    private var currentPath: String
    private var navigationStack: [String] = []
    private var selectedPaths = Set<String>()
    private var searchQuery: String?

    init(repository: LoadedRepository, client: GitHubClient) {
        self.repository = repository
        self.client = client
        self.folderSizes = SelectionResolver.folderSizes(for: repository.items)
        self.currentPath = ConsoleBrowser.initialPath(for: repository)
    }

    func run() async throws -> Set<String>? {
        while true {
            render()
            guard let line = readLine(strippingNewline: true) else {
                return nil
            }

            let action = try await handle(line)
            switch action {
            case .continueBrowsing:
                continue
            case .download:
                return selectedPaths
            case .quit:
                return nil
            }
        }
    }

    private func handle(_ line: String) async throws -> BrowserAction {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return .continueBrowsing
        }

        let items = visibleItems()

        if let number = Int(trimmed) {
            toggle(index: number, in: items)
            return .continueBrowsing
        }

        let parts = trimmed.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
        let command = parts.first.map { String($0).lowercased() } ?? ""
        let rest = parts.count > 1 ? String(parts[1]) : ""

        switch command {
        case "q", "quit", "exit":
            return .quit
        case "d", "download":
            if selectedPaths.isEmpty {
                printAndWait("Ничего не выбрано. Выбери файлы или папки номерами.")
                return .continueBrowsing
            }
            return .download
        case "?", "help":
            printAndWait(BrowserText.help)
        case "e", "enter":
            enterOrToggle(indexText: rest, in: items)
        case "cd", "open":
            open(indexText: rest, in: items)
        case "l", "back", "b", "..":
            goBack()
        case "a", "all":
            for item in items {
                selectedPaths.insert(item.path)
            }
        case "u", "none":
            for item in items {
                selectedPaths.remove(item.path)
            }
        case "clear-selection":
            selectedPaths.removeAll()
        case "/", "search":
            let query = rest.trimmingCharacters(in: .whitespacesAndNewlines)
            searchQuery = query.isEmpty ? nil : query
        case "clear":
            searchQuery = nil
        case "t", "toggle":
            toggleMany(rest, in: items)
        case "p", "preview":
            try await preview(indexText: rest, in: items)
        case "selected":
            showSelected()
        default:
            printAndWait("Неизвестная команда: \(trimmed)")
        }

        return .continueBrowsing
    }

    private func render() {
        clearScreen()

        let branch = repository.url.branch ?? "unknown"
        print("Репозиторий: \(repository.url.repoFullName) @ \(branch)")
        if repository.truncated {
            print("Внимание: GitHub пометил дерево как truncated, часть файлов может отсутствовать.")
        }

        if let searchQuery {
            print("Режим: поиск `\(searchQuery)`")
        } else {
            print("Папка: \(currentPath.isEmpty ? "/" : currentPath)")
        }

        print("Выбрано: \(selectedPaths.count). Команды: ? помощь, d скачать, q выйти")
        print(String(repeating: "-", count: 88))

        let items = visibleItems()
        if items.isEmpty {
            print("Нет элементов для отображения.")
        } else {
            for (offset, item) in items.enumerated() {
                let index = String(format: "%3d", offset + 1)
                let selected = selectionMarker(for: item)
                let kind = item.isDirectory ? "DIR " : "FILE"
                let size = item.isDirectory
                    ? formatSize(folderSizes[item.path])
                    : formatSize(item.size)
                let name = searchQuery == nil ? item.name : item.path
                print("\(index). \(selected) \(kind) \(name.padding(toLength: 52, withPad: " ", startingAt: 0)) \(size)")
            }
        }

        print(String(repeating: "-", count: 88))
        print("Команда: ", terminator: "")
        fflush(stdout)
    }

    private func visibleItems() -> [RepoItem] {
        if let searchQuery, !searchQuery.isEmpty {
            let lowered = searchQuery.lowercased()
            return repository.items
                .filter { $0.path.lowercased().contains(lowered) }
                .sorted { $0.path < $1.path }
        }

        let prefix = currentPath.isEmpty ? "" : currentPath + "/"
        let result = repository.items.filter { item in
            if currentPath.isEmpty {
                return !item.path.contains("/")
            }
            guard item.path.hasPrefix(prefix) else {
                return false
            }
            let remainder = item.path.dropFirst(prefix.count)
            return !remainder.contains("/")
        }

        return result.sorted { lhs, rhs in
            if lhs.kind != rhs.kind {
                return lhs.isDirectory && rhs.isFile
            }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }

    private func toggle(index: Int, in items: [RepoItem]) {
        guard let item = item(at: index, in: items) else {
            printAndWait("Нет элемента с номером \(index).")
            return
        }

        if selectedPaths.contains(item.path) {
            selectedPaths.remove(item.path)
        } else {
            selectedPaths.insert(item.path)
        }
    }

    private func toggleMany(_ text: String, in items: [RepoItem]) {
        let numbers = text
            .split(separator: " ")
            .compactMap { Int($0) }

        guard !numbers.isEmpty else {
            printAndWait("Передай номера: t 1 2 3")
            return
        }

        for number in numbers {
            toggle(index: number, in: items)
        }
    }

    private func open(indexText: String, in items: [RepoItem]) {
        guard let index = Int(indexText.trimmingCharacters(in: .whitespacesAndNewlines)),
              let item = item(at: index, in: items) else {
            printAndWait("Передай номер папки: cd 3")
            return
        }

        guard item.isDirectory else {
            printAndWait("Это файл, а не папка: \(item.path)")
            return
        }

        navigationStack.append(currentPath)
        currentPath = item.path
        searchQuery = nil
    }

    private func enterOrToggle(indexText: String, in items: [RepoItem]) {
        guard let index = Int(indexText.trimmingCharacters(in: .whitespacesAndNewlines)),
              let item = item(at: index, in: items) else {
            printAndWait("Передай номер элемента: e 1")
            return
        }

        if item.isDirectory {
            navigationStack.append(currentPath)
            currentPath = item.path
            searchQuery = nil
        } else {
            toggle(index: index, in: items)
        }
    }

    private func goBack() {
        searchQuery = nil

        if let previous = navigationStack.popLast() {
            currentPath = previous
            return
        }

        guard !currentPath.isEmpty else {
            return
        }

        currentPath = parentPath(of: currentPath)
    }

    private func preview(indexText: String, in items: [RepoItem]) async throws {
        guard let index = Int(indexText.trimmingCharacters(in: .whitespacesAndNewlines)),
              let item = item(at: index, in: items) else {
            printAndWait("Передай номер файла: p 4")
            return
        }

        guard item.isFile, let url = item.downloadURL else {
            printAndWait("Preview доступен только для файлов.")
            return
        }

        let data = try await client.fetchPreview(from: url)
        guard isProbablyText(data), let text = String(data: data, encoding: .utf8) else {
            printAndWait("Файл выглядит бинарным. Preview пропущен: \(item.path)")
            return
        }

        let lines = text
            .split(separator: "\n", omittingEmptySubsequences: false)
            .prefix(160)
            .enumerated()
            .map { number, line in String(format: "%4d | %@", number + 1, String(line)) }
            .joined(separator: "\n")

        printAndWait("Preview: \(item.path)\n\(String(repeating: "-", count: 88))\n\(lines)")
    }

    private func showSelected() {
        if selectedPaths.isEmpty {
            printAndWait("Пока ничего не выбрано.")
            return
        }

        let text = selectedPaths.sorted().joined(separator: "\n")
        printAndWait("Выбранные пути:\n\(text)")
    }

    private func item(at index: Int, in items: [RepoItem]) -> RepoItem? {
        guard index >= 1, index <= items.count else {
            return nil
        }
        return items[index - 1]
    }

    private func selectionMarker(for item: RepoItem) -> String {
        if selectedPaths.contains(item.path) {
            return "[x]"
        }

        let coveredByDirectory = selectedPaths.contains { selected in
            item.path.hasPrefix(selected + "/")
        }

        return coveredByDirectory ? "[~]" : "[ ]"
    }

    private func formatSize(_ size: Int64?) -> String {
        guard let size else {
            return ""
        }

        let value = Double(size)
        if size < 1024 {
            return "\(size) B"
        } else if size < 1024 * 1024 {
            return String(format: "%.1f KB", value / 1024.0)
        } else if size < 1024 * 1024 * 1024 {
            return String(format: "%.1f MB", value / 1024.0 / 1024.0)
        }
        return String(format: "%.1f GB", value / 1024.0 / 1024.0 / 1024.0)
    }

    private func printAndWait(_ message: String) {
        print("\n\(message)")
        print("\nНажми Enter, чтобы продолжить...", terminator: "")
        _ = readLine()
    }

    private func clearScreen() {
        guard ProcessInfo.processInfo.environment["TERM"] != "dumb" else {
            return
        }
        print("\u{001B}[2J\u{001B}[H", terminator: "")
    }

    private func isProbablyText(_ data: Data) -> Bool {
        !data.contains(0) && String(data: data, encoding: .utf8) != nil
    }

    private static func initialPath(for repository: LoadedRepository) -> String {
        let normalized = GitHubURL.normalizePath(repository.url.path)
        guard !normalized.isEmpty else {
            return ""
        }

        if repository.items.first(where: { $0.path == normalized })?.isFile == true {
            return parentPath(of: normalized)
        }

        return normalized
    }
}

private enum BrowserAction {
    case continueBrowsing
    case download
    case quit
}

private enum BrowserText {
    static let help = """
    Команды:
      <n>                 выбрать/снять файл или папку
      t <n...>            выбрать/снять несколько элементов
      e <n>               зайти в папку; если это файл — выбрать/снять его
      cd <n>              зайти в папку
      l, back, ..         подняться выше
      / <text>            поиск по полному пути
      clear               очистить поиск
      a                   выбрать все видимые элементы
      u                   снять выбор со всех видимых элементов
      clear-selection     снять весь выбор
      selected            показать выбранные пути
      p <n>               preview первых 16 KB файла
      d                   скачать выбранное
      q                   выйти
    """
}

private func parentPath(of path: String) -> String {
    let normalized = GitHubURL.normalizePath(path)
    guard let slashIndex = normalized.lastIndex(of: "/") else {
        return ""
    }
    return String(normalized[..<slashIndex])
}
