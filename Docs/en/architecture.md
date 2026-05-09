# Architecture

GitPluck is split into two targets:

```text
GitPluckCLI    executable target with argument parsing and console UI
GitPluckCore   reusable core with GitHub API, selection, and downloading logic
```

## Request Flow

```text
GitHub URL
  -> GitHubURL.parse
  -> GitHubClient.loadRepositoryTree
  -> ConsoleBrowser.run
  -> SelectionResolver.resolve
  -> Downloader.download
```

## URL Parsing

`GitHubURL` accepts:

- repository root URLs
- `tree/<branch>/<path>` URLs
- `blob/<branch>/<path>` URLs
- `owner/repo` shorthand

When no branch is specified, GitPluck requests repository metadata and uses the default branch returned by GitHub.

## Tree Loading

`GitHubClient` calls:

```text
GET /repos/<owner>/<repo>/git/trees/<branch>?recursive=1
```

The response is mapped into `RepoItem` values:

- directories become `.directory`
- blobs become `.file`
- file download URLs are built through `raw.githubusercontent.com`

If the original URL points to a subpath, the tree is scoped to that path.

## Browser State

`ConsoleBrowser` keeps local state:

- current folder path
- navigation stack
- selected paths
- active search query
- calculated folder sizes

Selection stores repository paths, not local file paths. This keeps the browser independent from the final output directory.

## Selection Resolution

`SelectionResolver` converts selected paths into concrete downloadable files.

If a selected path is a file, it is downloaded directly.

If a selected path is a folder, all nested files under that folder are included.

Nested selections are deduplicated by repository path.

## Downloading

`Downloader` writes files into:

```text
<output-directory>/<repository-relative-path>
```

Before writing a file, it creates all required parent directories.

## Git LFS Handling

Downloaded data is checked for a Git LFS pointer. If a pointer is detected:

1. GitPluck calls the LFS batch API.
2. If the batch API returns a download URL, GitPluck downloads the real object.
3. If the batch API fails, GitPluck tries a `media.githubusercontent.com` fallback URL.

---

[Back to documentation index](index.md)
