# @ps-semantic-release/Changelog

A plugin that creates or updates a Markdown changelog file with the generated release notes. It validates the configured changelog path, prepends the new release notes (optionally under a configured title), and writes the result back to disk.

---

## Configuration

- `file`:

  - Type: string
  - Required: no
  - Default: plugin default from `Context.Config.Default.plugins`: `CHANGELOG.md`
  - Description: Path to the changelog Markdown file to create or update. Must be a `.md` file.

- `title`:
  - Type: string
  - Required: no
  - Default: plugin default from `Context.Config.Default.plugins`: `""`
  - Description: Optional top-level title to preserve at the top of the changelog. If provided and the existing changelog starts with this title, the plugin will keep the title and prepend new notes after it.

---

## Behavior details

### `VerifyConditions`

- Validates that the configured `file` path is a valid filesystem path by calling `[System.IO.Path]::GetFullPath($this.Config.file)`. If this fails, the plugin throws a clear error.
- Ensures the configured `file` has a `.md` extension; otherwise throws an error indicating only Markdown files are supported.
- Logs start and completion of the verification step.

### `Prepare`

- Skips the step entirely when `Context.DryRun` is true and logs a warning indicating the skip.
- Reads `Context.NextRelease.Notes` and the configured `file` and `title`.
- If the changelog file exists:
  - Reads the existing file contents as UTF-8 and trims whitespace.
  - Sets status to indicate an update and preserves the existing content (minus the title if the title is present and matches).
- If the changelog file does not exist:
  - Sets status to indicate creation and prepares to write a new file.
- If a `title` is configured and the existing file starts with that title, the plugin preserves the title at the top and inserts the new notes after the title.
- Constructs the final contents by:
  - Trimming the new notes and ensuring a trailing newline.
  - Appending the previous content after a blank line (if any).
  - Prepending the configured title followed by two newlines when a title is configured.
- Writes the final contents to the configured `file` using UTF-8 encoding.
- Logs the file creation/update status and completes the step.

---

## Examples

### Minimal plugin config

```json
{
  "plugins": [
    [
      "@ps-semantic-release/Changelog",
      {
        "file": "CHANGELOG.md",
        "title": "# Changelog"
      }
    ]
  ]
}
```

### Typical changelog result (after Prepare)

```md
# Changelog

# [1.2.0](https://github.com/example/repo/compare/v1.1.0...v1.2.0) (2026-01-12)

### Features

- **Module:** Add new cmdlet to manage widgets ([abc1234](https://github.com/example/repo/commit/abc1234))

### Bug Fixes

- **API:** Fix null reference when response is empty ([def5678](https://github.com/example/repo/commit/def5678))

[previous changelog content preserved here]
```

---

## Logging and messages

- Logs start and completion for `VerifyConditions` and `Prepare`.
- On invalid file path: throws `"[<PluginName>] The file path of the Changelog plugin is invalid"`.
- On unsupported extension: throws `"[<PluginName>] Only markdown (.md) file is supported for the changelog."`.
- In DryRun mode: logs a warning that the `Prepare` step is skipped.
- After writing the file: logs a status message indicating whether the file was created or updated.

---

## Edge cases and notes

- **DryRun**: No file writes occur when `Context.DryRun` is true; the plugin logs the skip and returns early.
- **Title handling**: If a `title` is configured and the existing file begins with that exact title, the plugin preserves it and inserts new notes after the title. If the title is absent or does not match, the plugin treats the entire existing file as content to append after the new notes.
- **Encoding**: The plugin writes the changelog using UTF-8 encoding.
