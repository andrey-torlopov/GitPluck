<p align="center">
  <img src="Docs/banner.png" alt="GitPluck Logo" width="600"/>
</p>

<p align="center">
  <a href="https://swift.org">
    <img src="https://img.shields.io/badge/Swift-6.0-orange.svg?logo=swift" />
  </a>
  <a href="https://swift.org/package-manager/">
    <img src="https://img.shields.io/badge/SPM-compatible-green.svg" />
  </a>
  <img src="https://img.shields.io/badge/platform-macOS%2013%2B-blue.svg" />
</p>

# GitPluck

*Read this in other languages: [Русский](README-ru.md)*

`GitPluck` is a Swift command-line tool for downloading selected files and folders from a GitHub repository without cloning the whole repository.

It loads the repository tree through the GitHub API, lets you browse folders in the terminal, mark exactly what you need, and downloads the selected paths while preserving their directory structure.

## Key Features

- Select individual files and folders from a GitHub repository.
- Browse into folders and go back to parent directories from the console.
- Search by repository path.
- Preview the first 16 KB of text files before downloading.
- Download selected folders as nested files.
- Use a GitHub token through a flag, environment variable, or GitHub CLI.
- Built with Swift Package Manager and no third-party runtime dependencies.

## Quick Start

```bash
swift run GitPluck https://github.com/octocat/Hello-World
```

Inside the browser:

```text
e 1       # enter item 1 if it is a folder, otherwise select it
l         # go one level up
1         # select or unselect item 1
d         # download selected items
q         # quit
```

## Documentation

- [Installation](Docs/en/installation.md)
- [Quick Start](Docs/en/quick-start.md)
- [Commands](Docs/en/commands.md)
- [Configuration](Docs/en/configuration.md)
- [Architecture](Docs/en/architecture.md)
- [Full Documentation](Docs/en/index.md)

## Basic Usage

```bash
# Open repository browser
swift run GitPluck https://github.com/owner/repo

# Open a repository subfolder
swift run GitPluck https://github.com/owner/repo/tree/main/Sources

# Download into a custom directory
swift run GitPluck https://github.com/owner/repo --out ./Downloads

# Download directly into the target directory without creating repo subfolder
swift run GitPluck https://github.com/owner/repo --out ./Downloads --no-folder

# Use a GitHub token from GitHub CLI
swift run GitPluck https://github.com/owner/repo --token gh
```

## Requirements

- Swift 6.0 or newer
- macOS 13 or newer
- Network access to GitHub API and raw file URLs

## Project Layout

```text
Sources/GitPluckCLI/    Console executable and interactive browser
Sources/GitPluckCore/   GitHub API, selection resolution, downloading
Tests/                  Core behavior tests
Docs/                   Detailed documentation
```
