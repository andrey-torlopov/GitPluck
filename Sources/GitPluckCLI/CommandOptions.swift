import Foundation

struct CommandOptions {
    var url: String?
    var outputPath: String?
    var cwd = false
    var noFolder = false
    var token: String?
    var showHelp = false

    static func parse(_ arguments: [String]) throws -> CommandOptions {
        var options = CommandOptions()
        var index = 0

        while index < arguments.count {
            let argument = arguments[index]

            switch argument {
            case "--help", "-h":
                options.showHelp = true
            case "--cwd":
                options.cwd = true
            case "--no-folder":
                options.noFolder = true
            case "--out":
                index += 1
                guard index < arguments.count else {
                    throw CLIError.missingValue(argument)
                }
                options.outputPath = arguments[index]
            case let value where value.hasPrefix("--out="):
                options.outputPath = String(value.dropFirst("--out=".count))
            case "--token":
                index += 1
                guard index < arguments.count else {
                    throw CLIError.missingValue(argument)
                }
                options.token = arguments[index]
            case let value where value.hasPrefix("--token="):
                options.token = String(value.dropFirst("--token=".count))
            case let value where value.hasPrefix("-"):
                throw CLIError.unexpectedArgument(value)
            default:
                if options.url == nil {
                    options.url = argument
                } else {
                    throw CLIError.unexpectedArgument(argument)
                }
            }

            index += 1
        }

        return options
    }
}

enum CLIError: Error, LocalizedError, Equatable {
    case missingValue(String)
    case unexpectedArgument(String)
    case emptyURL

    var errorDescription: String? {
        switch self {
        case .missingValue(let flag):
            "Для \(flag) нужно передать значение"
        case .unexpectedArgument(let argument):
            "Неожиданный аргумент: \(argument)"
        case .emptyURL:
            "URL не может быть пустым"
        }
    }
}

enum HelpText {
    static let main = """
    GitPluck: точечное скачивание файлов и папок из GitHub репозитория

    Использование:
      GitPluck [URL] [--out PATH] [--cwd] [--no-folder] [--token TOKEN|auto|gh]

    Аргументы:
      URL                 GitHub URL вида https://github.com/owner/repo
                          Также поддерживаются /tree/<branch>/<path> и /blob/<branch>/<path>

    Флаги:
      --out PATH          Базовая папка для скачивания
      --cwd               Использовать текущую папку как базовую
      --no-folder         Не создавать подпапку с именем репозитория
      --token VALUE       GitHub token. Значения auto/gh читают токен через `gh auth token`
      -h, --help          Показать справку

    Переменные окружения:
      GITPLUCK_GITHUB_TOKEN, GITHUB_TOKEN

    Команды внутри браузера:
      <n>                 Выбрать/снять файл или папку по номеру
      t <n...>            Выбрать/снять несколько номеров
      e <n>               Зайти в папку; если это файл — выбрать/снять его
      cd <n>              Зайти в папку
      l, back, ..         Подняться выше
      / <text>            Искать по путям
      clear               Очистить поиск
      a                   Выбрать все видимые элементы
      u                   Снять выбор со всех видимых элементов
      selected            Показать выбранные пути
      p <n>               Preview первых 16 KB файла
      d                   Скачать выбранное
      q                   Выйти
    """
}
