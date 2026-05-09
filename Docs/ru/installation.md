# Установка

GitPluck распространяется как executable-пакет Swift Package Manager.

## Системные требования

- Swift 6.0 или новее
- macOS 13 или новее
- Доступ к `api.github.com`, `raw.githubusercontent.com` и, для Git LFS файлов, к `media.githubusercontent.com`

## Сборка из исходников

Из корня пакета:

```bash
swift build
```

Запуск executable через SwiftPM:

```bash
swift run GitPluck --help
```

## Release-сборка

Соберите оптимизированный бинарник:

```bash
swift build -c release
```

Бинарник будет создан здесь:

```text
.build/release/GitPluck
```

Его можно запустить напрямую:

```bash
.build/release/GitPluck https://github.com/octocat/Hello-World
```

## Локальная установка

Чтобы вызывать `GitPluck` из любой папки, скопируйте release-бинарник в директорию из `PATH`:

```bash
swift build -c release
cp .build/release/GitPluck /usr/local/bin/GitPluck
```

Если не хотите писать в `/usr/local/bin`, используйте пользовательскую директорию:

```bash
mkdir -p ~/.local/bin
cp .build/release/GitPluck ~/.local/bin/GitPluck
```

Убедитесь, что `~/.local/bin` есть в `PATH`.

## Проверка установки

```bash
GitPluck --help
```

При запуске через SwiftPM используйте:

```bash
swift run GitPluck --help
```

---

[Вернуться к главному README](../../README-ru.md) | [Быстрый старт](quick-start.md)
