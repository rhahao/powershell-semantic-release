# @ps-semantic-release/GitLab

A plugin that creates GitLab releases via the GitLab REST API. It validates configuration and CI environment, checks push permissions, optionally verifies release creation permissions, and publishes a release.

---

## Behavior details

### `VerifyConditions`

- Logs the start of verification.
- When running in CI (`Context.CI` is true):
  - Ensures the runner is GitLab CI by checking `GITLAB_CI` environment variable; if not running under GitLab CI, throws an error.
  - Ensures a GitLab token is available in `GITLAB_TOKEN` or `GL_TOKEN`; if missing, throws an error.
- Reads token from `GITLAB_TOKEN` or `GL_TOKEN` environment variables and stores it in `Config.token`.
- Derives `gitlabUrl` from `GITLAB_URL` or `GL_URL`, falling back to `https://GitLab.com`. Trailing slashes are trimmed.
- Computes `projectId` by removing the `gitlabUrl` prefix from `Context.Repository.Url`, trimming leading slashes, and URL-encoding the result (suitable for GitLab API project identifiers).
- Calls `Test-GitPushAccessCI -context $this.Context -token $token` to verify push access and logs the returned message.
- If running in CI, calls `TestReleasePermission()` to verify the token has sufficient permissions to create releases.
- Logs completion of verification.

### `Publish`

- Skips the step in DryRun mode and logs a warning.
- Logs the start of publishing.
- Builds the release payload:
  - `name`: `v<NextRelease.Version>`
  - `tag_name`: `v<NextRelease.Version>`
  - `description`: `Context.NextRelease.Notes`
- Serializes the payload to JSON with sufficient depth.
- Builds request headers with `PRIVATE-TOKEN: <token>` and `User-Agent`.
- Calls `POST {gitlabUrl}/api/v4/projects/{projectId}/releases` with the payload to create the release.
- Extracts `web_url` from the response and logs the published release URL.
- Logs completion of publishing.

---

## Examples

### Minimal plugin config

```json
{
  "plugins": [["@ps-semantic-release/GitLab"]]
}
```

**CI environment variables required (when running in CI):**

- `GITLAB_CI=true` (set by GitLab CI)
- `GITLAB_TOKEN` or `GL_TOKEN` — token with sufficient scope to read project metadata and create releases.

---

## Logging and messages

- **Start/Completed step** logs for `VerifyConditions` and `Publish`.
- Informational logs for:
  - Derived `gitlabUrl` and computed `projectId`.
  - Result of `Test-GitPushAccessCI` (push access check).
  - Published release URL after successful creation.
- Success logs:
  - When token has sufficient permissions to create releases (after `TestReleasePermission`).
  - When verification completes successfully.
- Errors and thrown messages:
  - `"[<PluginName>] You are not running PSSemanticRelease using GitLab Pipeline"` when CI is true but not running under GitLab CI.
  - `"[<PluginName>] No GitLab token (GITLAB_TOKEN or GL_TOKEN) found in CI environment."` when token is missing in CI.
  - `"[<PluginName>] Token does not have sufficient permissions to create GitLab releases."` when access level is insufficient.
  - `"[<PluginName>] Cannot access project or lacks permission: <message>"` for API/network errors.
- In DryRun mode: `Publish` logs a warning and returns without calling the API.
