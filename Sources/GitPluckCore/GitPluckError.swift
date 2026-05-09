import Foundation

public enum GitPluckError: Error, LocalizedError, Equatable {
    case invalidURL(String)
    case notGitHubURL
    case missingOwnerOrRepository
    case invalidHTTPResponse
    case invalidToken
    case rateLimitExceeded(String)
    case notFound(String)
    case apiError(String)
    case outputPathError(String)
    case emptySelection
    case pathNotFound(String)
    case unsupportedCommand(String)

    public var errorDescription: String? {
        switch self {
        case .invalidURL(let value):
            "Некорректный URL: \(value)"
        case .notGitHubURL:
            "URL должен указывать на github.com"
        case .missingOwnerOrRepository:
            "URL должен содержать владельца и репозиторий"
        case .invalidHTTPResponse:
            "Сервер вернул некорректный HTTP-ответ"
        case .invalidToken:
            "GitHub token отклонен"
        case .rateLimitExceeded(let scope):
            "GitHub API rate limit исчерпан для \(scope)"
        case .notFound(let resource):
            "Ресурс не найден: \(resource)"
        case .apiError(let message):
            "Ошибка GitHub API: \(message)"
        case .outputPathError(let message):
            "Некорректная папка для скачивания: \(message)"
        case .emptySelection:
            "Ничего не выбрано"
        case .pathNotFound(let path):
            "Путь не найден в дереве репозитория: \(path)"
        case .unsupportedCommand(let command):
            "Неизвестная команда: \(command)"
        }
    }
}
