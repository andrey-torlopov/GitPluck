# Quick Start

This guide shows the shortest path from a GitHub URL to a downloaded file.

## Open a Repository

From the package root:

```bash
swift run GitPluck https://github.com/octocat/Hello-World
```

GitPluck will:

1. Parse the GitHub URL.
2. Detect the repository default branch when the URL does not specify a branch.
3. Load the repository tree from the GitHub API.
4. Show an interactive console browser.

## Select and Download

In the browser, type commands into the `Command:` prompt.

For the `octocat/Hello-World` repository, there is one visible file:

```text
1
d
```

That means:

- `1` selects item 1.
- `d` downloads selected items.

By default, GitPluck downloads into the user's Downloads directory and creates a subfolder named after the repository.

## Browse Folders

Use:

```text
e 1
```

If item 1 is a folder, GitPluck enters it.
If item 1 is a file, GitPluck selects or unselects it.

To go one level up:

```text
l
```

At the repository root, `l` does nothing.

## Search Paths

```text
/ Sources
```

This filters visible items by full repository path.

Clear search:

```text
clear
```

## Choose Output Directory

```bash
swift run GitPluck https://github.com/owner/repo --out ./Downloaded
```

Skip the repository subfolder:

```bash
swift run GitPluck https://github.com/owner/repo --out ./Downloaded --no-folder
```

---

[Back to main README](../../README.md) | [Commands](commands.md)
