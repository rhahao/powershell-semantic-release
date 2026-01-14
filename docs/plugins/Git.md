# @ps-semantic-release/Git

A plugin that commits, tags, and pushes release-related changes to the remote repository. It can be configured to include specific files (like a changelog or build artifacts) in a release commit.

---

## Configuration

- `message`:

  - **Type:** string
  - **Required:** no
  - **Default:** `"chore(release): {NextRelease.Version} [skip ci]\n\n{NextRelease.Notes}"`
  - **Description:** A template for the release commit message. The plugin will replace placeholders like `{NextRelease.Version}` with their actual values.

- `assets`:
  - **Type:** array of strings
  - **Required:** no
  - **Default:** none
  - **Description:** An array of file paths or glob patterns (using PowerShell's wildcard syntax, like `*.log`) to include in the release commit. For example, `["dist/**", "CHANGELOG.md"]`.

---

## Behavior details

### `VerifyConditions`

This step performs a quick sanity check. It verifies that if you have defined `assets`, the configuration is valid and not empty. 

### `Prepare`

This step prepares the release commit. It is skipped in `DryRun` mode.

1.  **Generates the commit message** by filling out the `message` template.
2.  **Finds matching files** by searching for any modified files that match the patterns in the `assets` array.
3.  **Commits the files.** If any matching files are found, the plugin will stage and commit them using the generated message. It also ensures the Git user identity is configured for the commit.

### `Publish`

This step tags the release and pushes changes to the remote repository. It is also skipped in `DryRun` mode.

1.  **Pushes the release commit** to the current branch.
2.  **Pushes the Git tag** created by the core engine for the new version (e.g., `v1.2.0`).

---

## Examples

### Committing the CHANGELOG

This configuration will commit any changes to `CHANGELOG.md` in a release commit.

```json
{
  "plugins": [
    [
      "@ps-semantic-release/Git",
      {
        "assets": ["CHANGELOG.md"]
      }
    ]
  ]
}
```

### Typical Flow (when a `CHANGELOG.md` is modified)

1.  **`Prepare`**: The plugin stages and commits the updated `CHANGELOG.md` with a message like `chore(release): 1.2.0 [skip ci]...`.
2.  **`Publish`**: The plugin pushes the new commit to your branch and then pushes the `v1.2.0` tag (created by the engine).

---

### Logging and Messages

- The plugin logs when it starts and completes each step.
- It will log a warning and skip the `Prepare` and `Publish` steps when running in `DryRun` mode.
- If `assets` are configured but no matching files are found to commit, a failure will be logged.
- Throws an error if the `assets` configuration is present but empty.
