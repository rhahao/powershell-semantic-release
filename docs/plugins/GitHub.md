# @ps-semantic-release/GitHub

A plugin that creates GitHub releases via the GitHub REST API. It validates configuration and CI environment, checks push permissions, optionally verifies release creation permissions by creating and deleting a draft release, and publishes a release with the generated release notes.

---

## Configuration

- `assets`:
  - **Type:** array of strings
  - **Required:** no
  - **Default:** none
  - **Description:** List of file paths to upload to the GitHub release. If present, the plugin validates that `assets` is an array; actual upload behavior is not implemented in the provided code and would need to be added if required.

**Note:** The plugin derives `repo`, `githubUrl`, and `githubApiUrl` from environment variables and the repository URL in `Context.Repository.Url`. Tokens are read from `GITHUB_TOKEN` or `GH_TOKEN` environment variables when running in CI.

---

## Behavior details

### `VerifyConditions`

- Logs the start of verification.
- Validates `assets` shape: if `assets` is present and not an array, throws an error instructing the user to provide an array of files.
- When running in CI (`Context.CI` is true):
  - Ensures the runner is GitHub Actions by checking `GITHUB_ACTIONS` environment variable; if not running under GitHub Actions, throws an error.
  - Ensures a GitHub token is available in `GITHUB_TOKEN` or `GH_TOKEN`; if missing, throws an error.
- Derives `githubUrl` from `GITHUB_SERVER_URL`, `GITHUB_URL`, or `GH_URL` environment variables, falling back to `https://GitHub.com`. Trailing slashes are trimmed.
- Derives `githubApiUrl` from `GITHUB_API_URL` or `GH_API_URL`, falling back to `https://api.GitHub.com`. Trailing slashes are trimmed.
- Computes `repo` by removing the `githubUrl` prefix from `Context.Repository.Url` and trimming leading slashes (resulting in `owner/repo`).
- Reads token from `GITHUB_TOKEN` or `GH_TOKEN` environment variables and stores it in `Config.token`.
- Calls `Test-GitPushAccessCI -context $this.Context -token $token` to verify push access and logs the returned message.
- If running in CI, calls `TestReleasePermission()` to attempt creating and deleting a draft release as a permission check.
- Logs completion of verification.

### `Publish`

- Skips the step in DryRun mode and logs a warning.
- Logs the start of publishing.
- Builds the release payload:
  - `tag_name`: `v<NextRelease.Version>`
  - `name`: same as tag
  - `body`: `Context.NextRelease.Notes`
  - `prerelease`: `Context.NextRelease.Prerelease`
  - `draft`: `false`
- Serializes the payload to JSON with sufficient depth.
- Builds request headers with `Authorization: Bearer <token>`, `Accept: application/vnd.GitHub+json`, and `User-Agent`.
- Calls `POST $githubApiUrl/repos/$repo/releases` with the payload to create the release.
- Extracts `html_url` from the response and logs the published release URL.
- Logs completion of publishing.

---

## Examples

### Minimal plugin config

```json
{
  "plugins": ["@ps-semantic-release/GitHub"]
}
```

**CI environment variables required (when running in CI):**

- `GITHUB_ACTIONS=true` (set by GitHub Actions)
- `GITHUB_TOKEN` or `GH_TOKEN` — token with `repo` scope to create releases.

---

## Logging and messages

- **Start/Completed step** logs for `VerifyConditions` and `Publish`.
- Informational logs for:
  - Validation of `assets` shape.
  - Derived `githubUrl`, `githubApiUrl`, and computed `repo`.
  - Result of `Test-GitPushAccessCI` (push access check).
  - Published release URL after successful creation.
- Success logs:
  - When allowed to create releases (after `TestReleasePermission`).
  - When verification completes successfully.
- Errors and thrown messages:
  - `"[<PluginName>] Specify the array of files to upload for a release."` when `assets` is not an array.
  - `"[<PluginName>] You are not running PSSemanticRelease using GitHub Action"` when CI is true but not running under GitHub Actions.
  - `"[<PluginName>] No GitHub token (GITHUB_TOKEN or GH_TOKEN) found in CI environment."` when token is missing in CI.
  - Any HTTP or network errors from the GitHub API are rethrown for upstream handling.
- In DryRun mode: `Publish` logs a warning and returns without calling the API.
