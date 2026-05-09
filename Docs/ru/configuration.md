# Настройка

Сейчас GitPluck использует только runtime-настройки. Постоянный конфигурационный файл не создается.

## GitHub authentication

Аутентификация необязательна для публичных репозиториев, но полезна при ограничениях GitHub API или при доступе к приватным репозиториям, которые может читать ваш token.

GitPluck ищет token в таком порядке:

1. `--token TOKEN`
2. `--token auto` или `--token gh`, что запускает `gh auth token`
3. `GITPLUCK_GITHUB_TOKEN`
4. `GHGRAB_GITHUB_TOKEN` для обратной совместимости с первоначальным прототипом
5. `GITHUB_TOKEN`
6. `gh auth token`, если GitHub CLI установлен и авторизован

## Переменные окружения

```bash
export GITPLUCK_GITHUB_TOKEN="YOUR_TOKEN"
GitPluck https://github.com/owner/repo
```

Также поддерживается стандартная GitHub-переменная:

```bash
export GITHUB_TOKEN="YOUR_TOKEN"
GitPluck https://github.com/owner/repo
```

## Token из GitHub CLI

Если вы уже используете GitHub CLI:

```bash
gh auth login
GitPluck https://github.com/owner/repo --token gh
```

`--token gh` можно не указывать: GitPluck также пробует `gh auth token` как последний fallback.

## Папка скачивания

По умолчанию:

```text
~/Downloads/<repo-name>/
```

Указать базовую директорию:

```bash
GitPluck https://github.com/owner/repo --out ./Downloaded
```

Использовать текущую директорию:

```bash
GitPluck https://github.com/owner/repo --cwd
```

Не создавать подпапку с именем репозитория:

```bash
GitPluck https://github.com/owner/repo --out ./Downloaded --no-folder
```

## Git LFS

Если скачанный файл оказывается Git LFS pointer, GitPluck пытается получить реальный объект через Git LFS batch API.

Если это не удалось, используется fallback через media URL:

```text
https://media.githubusercontent.com/media/<owner>/<repo>/<branch>/<path>
```

---

[Вернуться к индексу документации](index.md)
