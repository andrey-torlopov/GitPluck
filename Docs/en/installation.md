# Installation

GitPluck is distributed as a Swift Package Manager executable.

## System Requirements

- Swift 6.0 or newer
- macOS 13 or newer
- Network access to `api.github.com`, `raw.githubusercontent.com`, and, for Git LFS files, `media.githubusercontent.com`

## Build from Source

From the package root:

```bash
swift build
```

Run the executable through SwiftPM:

```bash
swift run GitPluck --help
```

## Release Build

Build an optimized binary:

```bash
swift build -c release
```

The binary will be created at:

```text
.build/release/GitPluck
```

You can run it directly:

```bash
.build/release/GitPluck https://github.com/octocat/Hello-World
```

## Optional Local Install

If you want to call `GitPluck` from any directory, copy the release binary into a directory from your `PATH`:

```bash
swift build -c release
cp .build/release/GitPluck /usr/local/bin/GitPluck
```

Use a user-local directory if you do not want to write to `/usr/local/bin`:

```bash
mkdir -p ~/.local/bin
cp .build/release/GitPluck ~/.local/bin/GitPluck
```

Make sure `~/.local/bin` is in your `PATH`.

## Verify Installation

```bash
GitPluck --help
```

When running through SwiftPM, use:

```bash
swift run GitPluck --help
```

---

[Back to main README](../../README.md) | [Quick Start](quick-start.md)
