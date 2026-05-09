# Архитектура

GitPluck разделен на два target:

```text
GitPluckCLI    executable target с разбором аргументов и консольным UI
GitPluckCore   переиспользуемое ядро с GitHub API, выбором и скачиванием
```

## Поток выполнения

```text
GitHub URL
  -> GitHubURL.parse
  -> GitHubClient.loadRepositoryTree
  -> ConsoleBrowser.run
  -> SelectionResolver.resolve
  -> Downloader.download
```

## Разбор URL

`GitHubURL` принимает:

- URL корня репозитория
- URL вида `tree/<branch>/<path>`
- URL вида `blob/<branch>/<path>`
- короткую форму `owner/repo`

Если ветка не указана, GitPluck запрашивает метаданные репозитория и берет default branch, который вернул GitHub.

## Загрузка дерева

`GitHubClient` вызывает:

```text
GET /repos/<owner>/<repo>/git/trees/<branch>?recursive=1
```

Ответ преобразуется в значения `RepoItem`:

- директории становятся `.directory`
- blobs становятся `.file`
- URL для скачивания файлов строятся через `raw.githubusercontent.com`

Если исходный URL указывает на подпуть, дерево ограничивается этим путем.

## Состояние браузера

`ConsoleBrowser` хранит локальное состояние:

- текущий путь папки
- стек навигации
- выбранные пути
- активный поисковый запрос
- рассчитанные размеры папок

Выбор хранит пути репозитория, а не локальные пути. Поэтому браузер не зависит от финальной директории скачивания.

## Разрешение выбора

`SelectionResolver` превращает выбранные пути в конкретные файлы для скачивания.

Если выбран файл, он скачивается напрямую.

Если выбрана папка, в скачивание попадают все вложенные файлы внутри этой папки.

Вложенные выборы дедуплицируются по пути в репозитории.

## Скачивание

`Downloader` записывает файлы в:

```text
<output-directory>/<repository-relative-path>
```

Перед записью файла создаются все нужные родительские директории.

## Обработка Git LFS

Скачанные данные проверяются на Git LFS pointer. Если pointer найден:

1. GitPluck вызывает LFS batch API.
2. Если batch API возвращает download URL, GitPluck скачивает реальный объект.
3. Если batch API не сработал, GitPluck пробует fallback URL через `media.githubusercontent.com`.

---

[Вернуться к индексу документации](index.md)
