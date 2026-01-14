# @ps-semantic-release/CommitAnalyzer

A plugin that analyzes conventional commits to determine whether a release is needed and what semantic version bump to apply. It reads configured release rules, filters commits, determines the highest-impact release type (patch, minor, major), and sets `NextRelease.Type` and `NextRelease.Version` in the pipeline context.

---

## Configuration

- `releaseRules`:
  - Type: array of objects
  - Required: no
  - Default: plugin default rules from `Context.Config.Default.plugins`
    ```json
    [
      { "type": "fix", "release": "patch", "section": "Bug Fixes" },
      { "type": "feat", "release": "minor", "section": "Features" }
    ]
    ```
  - Description: Array of rule objects that map commit `type` (and optionally `scope`) to a `release` (`patch` or `minor`). If missing or empty, the plugin will load defaults from the project default plugin config.

**Note:** The plugin filters configured `releaseRules` to only include rules whose `release` value is one of `patch` or `minor`. `major` is not accepted as a configured `release` value — major releases are inferred from commit `Breaking` flags.

---

## Rule object shape (example)

A `releaseRules` entry is expected to be an object similar to:

```json
{ "type": "fix", "release": "patch", "section": "Bug fixes" }
```

Multiple rules can be provided; the plugin will match commit Type against type in each rule.

---

## Context and environment

- **Context.Config.Project.plugins** — used to locate and update the plugin config in the running project config.
- **Context.Config.Default.plugins** — used as a fallback when the plugin config lacks `releaseRules`.
- **Context.Commits.List** — populated by `Get-ConventionalCommits -context $this.Context` during `VerifyConditions`.
- **Context.Commits.Formatted** — human-friendly summary like `1 commit` or `N commits`.
- **Context.NextRelease.Type** — set to the computed release type (major, minor, patch, or null when no release).
- **Context.NextRelease.Version** — set to the computed next semantic version via `Get-NextSemanticVersion -context $this.Context`.
- **Context.Abort** — set to `$true` when no release is needed to stop the pipeline.

---

## Behavior details

### `VerifyConditions`

- Calls `Get-ConventionalCommits -context $this.Context` to collect commits since the last release.
- Stores the commit list in `Context.Commits.List` and a formatted count in `Context.Commits.Formatted`.
- If no commits are found, logs that no release is needed and sets `Context.Abort = $true`.
- If commits are found, logs the number of commits and continues.

### `AnalyzeCommits`

- Iterates each commit in `Context.Commits.List`.
- For each commit:
  - Logs the commit message.
  - Finds matching rule(s) in `Config.releaseRules` by comparing `commit.Type` to rule `type`.
  - If no matching rule is found, the commit does not trigger a release.
  - If the commit has `Breaking -eq $true`, the plugin treats it as a `major` release trigger.
  - Otherwise, it uses the matched rule's `release` value (`patch` or `minor`).
- Aggregates all triggered release types and deduplicates them.
- Selects the highest-impact release according to precedence:
  1. `major` (if any breaking changes found)
  2. `minor` (if any minor triggers found and no major)
  3. `patch` (if only patch triggers found)
- If no release types were triggered, sets `Context.Abort = $true`.
- If a release is required:
  - Calls `Get-NextSemanticVersion -context $this.Context` to compute the next version.
  - Sets `Context.NextRelease.Version` and `Context.NextRelease.Type`.
  - Logs the computed next version and whether it is a channeled prerelease based on `Context.NextRelease.Channel` and `Context.Repository.BranchCurrent`.

---

## Example `semantic-release.json` snippet

```json
{
  "plugins": [
    [
      "@ps-semantic-release/CommitAnalyzer",
      {
        "releaseRules": [
          { "type": "fix", "release": "patch" },
          { "type": "feat", "release": "minor" },
          { "type": "chore", "release": "patch" }
        ]
      }
    ]
  ]
}
```

**Fallback behavior:** If `releaseRules` is omitted or empty, the plugin will use the default rules defined in `Context.Config.Default.plugins` for the `@ps-semantic-release/CommitAnalyzer` plugin.

### Logging and messages

- **Start/Completed step** logs for `VerifyConditions` and `AnalyzeCommits`.
- Informational logs for each analyzed commit and the reason it did or did not trigger a release.
- Final informational log summarizing the analysis and the resulting release type (e.g., `Analysis of 3 commits completed: minor release`).
- When no commits are found or no release is needed, the plugin sets `Context.Abort = $true` and logs the outcome.

---

### Edge cases and notes

- **Breaking changes**: Any commit with `Breaking -eq $true` forces a `major` release regardless of configured `releaseRules`.
- **Configured major rules**: The plugin filters configured rules to only `patch` and `minor`. If a user configures a rule with `release: "major"`, it will be ignored by `EnsureConfig`. Major releases must come from commit `Breaking` flags.
- **No commits**: The plugin aborts the release flow when no conventional commits are found.
