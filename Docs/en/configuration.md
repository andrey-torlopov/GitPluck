# Configuration

GitPluck currently uses runtime configuration only. It does not write a persistent config file.

## GitHub Authentication

Authentication is optional for public repositories, but it is useful when GitHub API limits are reached or when accessing private repositories that your token can read.

GitPluck resolves a token in this order:

1. `--token TOKEN`
2. `--token auto` or `--token gh`, which runs `gh auth token`
3. `GITPLUCK_GITHUB_TOKEN`
4. `GHGRAB_GITHUB_TOKEN` for backward compatibility with the original prototype
5. `GITHUB_TOKEN`
6. `gh auth token`, if GitHub CLI is installed and authenticated

## Environment Variables

```bash
export GITPLUCK_GITHUB_TOKEN="YOUR_TOKEN"
GitPluck https://github.com/owner/repo
```

The generic GitHub environment variable is also supported:

```bash
export GITHUB_TOKEN="YOUR_TOKEN"
GitPluck https://github.com/owner/repo
```

## GitHub CLI Token

If you already use GitHub CLI:

```bash
gh auth login
GitPluck https://github.com/owner/repo --token gh
```

You can omit `--token gh`; GitPluck also tries `gh auth token` as a final fallback.

## Output Directory

Default output:

```text
~/Downloads/<repo-name>/
```

Use a custom base directory:

```bash
GitPluck https://github.com/owner/repo --out ./Downloaded
```

Use the current working directory:

```bash
GitPluck https://github.com/owner/repo --cwd
```

Do not create a repository subfolder:

```bash
GitPluck https://github.com/owner/repo --out ./Downloaded --no-folder
```

## Git LFS

When a downloaded file is a Git LFS pointer, GitPluck tries to resolve the actual object through the Git LFS batch API.

If that fails, it falls back to the media URL form:

```text
https://media.githubusercontent.com/media/<owner>/<repo>/<branch>/<path>
```

---

[Back to documentation index](index.md)
