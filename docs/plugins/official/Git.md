# @ps-semantic-release/Git

A plugin that stages, commits, tags, and pushes release-related changes to the repository. It validates the working tree, stages configured asset files, commits with a templated message, creates an annotated tag for the new version, and pushes branch and tag to the remote.

---

## Configuration

- `message`:

  - **Type:** string
  - **Required:** no
  - **Default:** plugin default from `Context.Config.Default.plugins`
    ```json
    "chore(release): ${nextRelease.version} [skip ci]"
    ```
  - **Description:** Commit message template. The plugin expands the template against the pipeline `Context` using `Expand-ContextString` before committing.

- `assets`:
  - **Type:** string or array of strings (path globs)
  - **Required:** no
  - **Default:** none
  - **Description:** Files or globs to include in the release commit (for example, `["dist/**", "CHANGELOG.md"]`). The plugin coerces a single string into an array for consistent processing.

---

## Behavior details

### `VerifyConditions`

- Logs the start of verification.
- Calls `Get-GitStatus` to ensure the working tree is clean; if not clean, throws an error instructing the user to commit or stash changes.
- Validates `assets` presence and shape; if `assets` is an array but empty, throws an error indicating at least one asset must be specified.
- When not in DryRun, calls `Set-GitIdentity` to ensure commits are authored with a configured identity.
- Retrieves the current semantic version tag using `Get-CurrentSemanticVersion -context $this.Context.Config.Project.unifyTag` and stores it in `Context.CurrentVersion.Branch`.
- Logs whether a previous release tag was found or that all commits will be considered when no previous release exists.
- Logs completion of verification.

### `Prepare`

- Skips the step in DryRun mode and logs a warning.
- Logs the start of preparation.
- Expands the commit message template using `Expand-ContextString -context $this.Context -template $messageTemplate`.
- Collects modified files via `Get-GitModifiedFiles` and matches them against each `assets` path rule (glob-like `-like` matching).
- Builds a list of full file paths to commit.
- If `assets` were configured but no matching files are found, logs a failure via `Add-FailureLog`.
- If files are found:
  - Logs the number of files to commit.
  - Stages the files (`git add <files>`).
  - Performs `git restore .` and `git restore --staged .` to reset working tree and staged state, then re-stages the intended files to ensure only desired files are committed.
  - Commits with the expanded commit message (`git commit -m <message> --quiet`).
- Computes the tag name as `v<NextRelease.Version>`.
- Checks for tag existence with `Test-GitTagExist`; if the tag already exists, throws an error.
- In non-DryRun mode, creates an annotated tag using the commit message as the annotation, with a zero-width-space replacement for leading `#` characters to avoid Markdown header interpretation in tag annotations.
- Logs completion of the preparation step.

### `Publish`

- Skips the step in DryRun mode and logs a warning.
- Logs the start of publishing.
- Determines `currentBranch` from `Context.Repository.BranchCurrent`, `nextVersion` from `Context.NextRelease.Version`, and whether assets are present.
- Builds the push target:
  - Always pushes the tag `v<nextVersion>`.
  - If both a commit message and assets are present, pushes the current branch as well (so the release commit is pushed alongside the tag).
- Executes `git push origin <itemsToPush>` and suppresses non-critical output.
- Logs a confirmation that the Git release has been prepared (including the version).
- Logs completion of the publish step.

---

## Examples

### Minimal plugin config

```json
{
  "plugins": [
    [
      "@ps-semantic-release/Git",
      {
        "message": "chore(release): ${nextRelease.version} [skip ci]",
        "assets": ["dist/**", "CHANGELOG.md"]
      }
    ]
  ]
}
```

### Typical flow (non-DryRun)

1. `VerifyConditions` ensures working tree is clean and sets git identity.
2. `Prepare` stages `dist/**` and `CHANGELOG.md`, commits with expanded message, creates `v1.2.0` annotated tag.
3. `Publish` pushes `main` (if assets were committed) and `v1.2.0` to `origin`.

---

### Logging and messages

- **Start/Completed step** logs for `VerifyConditions`, `Prepare`, and `Publish`.
- Informational logs for:
  - Clean working tree checks and found previous tag.
  - Number of files found to commit.
  - Tag creation and push preparation.
- Failure logs and thrown errors for:
  - Dirty working tree: `"[<PluginName>] Working tree is not clean. Commit or stash changes before releasing."`
  - Missing assets when required: `"[<PluginName>] At least one asset needs to be specified."`
  - Tag already exists: `Tag v<version> already exists`.
  - Cannot find files listed in assets config: `Cannot find files listed in assets config` (via `Add-FailureLog`).
- In DryRun mode: warnings that `Prepare` and `Publish` steps are skipped.
