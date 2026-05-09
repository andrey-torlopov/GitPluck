# Commands

GitPluck has two command layers:

- startup flags passed to `GitPluck`
- interactive browser commands typed after the repository tree is loaded

## Startup Flags

```bash
GitPluck [URL] [--out PATH] [--cwd] [--no-folder] [--token TOKEN|auto|gh]
```

When running through SwiftPM:

```bash
swift run GitPluck -- [URL] [--out PATH] [--cwd] [--no-folder] [--token TOKEN|auto|gh]
```

SwiftPM also accepts common usage without `--`:

```bash
swift run GitPluck https://github.com/owner/repo
```

### Arguments

| Argument | Description |
| --- | --- |
| `URL` | GitHub repository URL. If omitted, GitPluck asks for it interactively. |

Supported URL forms:

```text
https://github.com/owner/repo
https://github.com/owner/repo/tree/main/path/to/folder
https://github.com/owner/repo/blob/main/path/to/file
owner/repo
```

### Flags

| Flag | Description |
| --- | --- |
| `--out PATH` | Base output directory. |
| `--cwd` | Use the current working directory as the base output directory. |
| `--no-folder` | Download directly into the base output directory instead of creating a repository subfolder. |
| `--token TOKEN` | Use a GitHub token for this run. |
| `--token auto` | Read token through `gh auth token`. |
| `--token gh` | Same as `--token auto`. |
| `-h`, `--help` | Show help. |

## Interactive Browser Commands

| Command | Description |
| --- | --- |
| `<n>` | Select or unselect visible item `n`. |
| `t <n...>` | Select or unselect multiple visible items. Example: `t 1 2 5`. |
| `e <n>` | Enter item `n` if it is a folder; otherwise select or unselect it. |
| `cd <n>` | Enter folder `n`. If `n` is a file, GitPluck shows an error. |
| `l` | Go one level up. Does nothing at repository root. |
| `back`, `b`, `..` | Same as `l`. |
| `/ <text>` | Search visible items by full repository path. |
| `clear` | Clear active search. |
| `a` | Select all visible items. |
| `u` | Unselect all visible items. |
| `clear-selection` | Clear the whole selection. |
| `selected` | Print selected paths. |
| `p <n>` | Preview the first 16 KB of text file `n`. |
| `d` | Download selected items. |
| `q`, `quit`, `exit` | Quit without downloading. |
| `?`, `help` | Show browser help. |

## Output Layout

By default:

```text
~/Downloads/<repo-name>/<selected-paths>
```

With `--out ./tmp`:

```text
./tmp/<repo-name>/<selected-paths>
```

With `--out ./tmp --no-folder`:

```text
./tmp/<selected-paths>
```

---

[Back to documentation index](index.md)
