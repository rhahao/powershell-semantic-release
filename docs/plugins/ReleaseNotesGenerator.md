# @ps-semantic-release/ReleaseNotesGenerator

A plugin that builds human-friendly release notes from conventional commits. It groups commits into sections based on the `CommitAnalyzer` plugin’s `releaseRules`, sorts commits per configured keys, generates a versioned title with an optional compare link, and writes the result to `Context.NextRelease.Notes`.

---

## Configuration

- `commitsSort`:

  - Type: array of strings
  - Required: no
  - Default: plugin default from `Context.Config.Default.plugins`
    ```json
    ["scope", "subject"]
    ```
  - Description: Array of sort keys passed to `Format-SortCommits` to order commits within each section (for example, `["scope","subject"]`). If missing, the plugin will load the default `commitsSort` from the project default plugin config.

---

## Behavior details

### `GenerateNotes`

- Starts by logging the step and reading `Context.Commits.List`.
- Loads `CommitAnalyzer`’s `releaseRules` and builds a lookup hashtable mapping commit `type` → `{ Release, Section }`.
- Iterates commits and groups them into an ordered `sections` map keyed by section name; commits whose `Type` is not present in the `releaseRules` are skipped.
- If no sections are populated, logs `No user facing changes` and returns early.
- Builds the release notes lines:
  - Determines `repoUrl`, `versionPrev` (from `Context.CurrentVersion.Branch`), `versionNext` (from `Context.NextRelease.Version`), and `date` (YYYY-MM-DD).
  - Generates a compare URL via `Get-CompareUrl -RepositoryUrl <repoUrl> -FromVersion <versionPrev> -ToVersion <versionNext>`; if present, the version in the title is linked.
  - Uses a single `#` title for non-patch releases and `##` for patch releases, then appends the date.
  - Orders sections according to the order of `CommitAnalyzer`’s `releaseRules` (unique `section` values).
  - For each section:
    - Adds a `### <Section>` heading.
    - Sorts commits in the section using `Format-SortCommits -Commits <sectionCommits> -SortKeys <commitsSort>`.
    - For each commit, builds a bullet line in the form `* **<Scope>:** <Subject> ([(shortSha)](<commitUrl>))` when a commit URL is available via `Get-CommitUrl`.
- Joins the lines with newline separators and assigns the resulting markdown string to `Context.NextRelease.Notes`.
- Logs completion of the step.

---

## Examples

### Minimal example config

```json
{
  "plugins": [
    [
      "@ps-semantic-release/ReleaseNotesGenerator",
      {
        "commitsSort": ["Scope", "Subject"]
      }
    ]
  ]
}
```

### Typical generated release notes (example)

```md
# [1.2.0](https://github.com/example/repo/compare/v1.1.0...v1.2.0) (2026-01-12)

### Features

- **Module:** Add new cmdlet to manage widgets ([abc1234](https://github.com/example/repo/commit/abc1234))

### Bug Fixes

- **API:** Fix null reference when response is empty ([def5678](https://github.com/example/repo/commit/def5678))
```

---

### Logging and messages

- **Start/Completed step** logs for the `GenerateNotes` step.
- Logs `No user facing changes` when no commits match configured sections.
- Uses `Add-InformationLog` for progress and `Add-SuccessLog` on completion.
- Any failures should surface via thrown exceptions (consistent with other plugins’ patterns).

---

### Edge cases and notes

- **Dependency on CommitAnalyzer**: The plugin relies on `@ps-semantic-release/CommitAnalyzer` to provide `releaseRules` with `type` → `section` mappings. If `CommitAnalyzer` is misconfigured or absent, sections will be empty and no notes will be generated.
- **Missing commit URLs**: If `Get-CommitUrl` returns no link, the commit line omits the SHA link.
- **No user-facing changes**: When no commits match any section, the plugin logs and returns without modifying `Context.NextRelease.Notes`.
- **Ordering**: Section order follows the order of `CommitAnalyzer`’s `releaseRules` as defined in the project config. Commit ordering within a section follows `commitsSort`.
