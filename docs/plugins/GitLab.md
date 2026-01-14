# @ps-semantic-release/GitLab

A plugin that publishes releases to GitLab. It can upload release assets and creates a GitLab Release with the generated release notes.

---

## Configuration

- `assets`:
  - **Type:** array of objects
  - **Required:** no
  - **Default:** none
  - **Description:** A list of assets to include in the GitLab release. Each asset is an object that can have the following properties:
    - `path`: The path to the file or directory to upload. If a directory is provided, it will be compressed into a `.zip` file before being uploaded to the project.
    - `url`: A direct link to an asset. This will be added to the release's `links`.
    - `label`: A description for the asset link. It will be used as the link's `name`.

---

## Behavior details

### `VerifyConditions`

This step ensures that the plugin is running in a valid environment.

- **Validates `assets`**: Checks that the `assets` configuration is an array, if provided.
- **Checks CI environment**: If running in a CI environment, it verifies that:
  - It is running in a GitLab CI/CD pipeline.
  - A `GITLAB_TOKEN` or `GL_TOKEN` is available.
- **Determines GitLab URLs**: It automatically determines the correct GitLab instance URL from CI environment variables (`CI_SERVER_HOST`, `GITLAB_URL`, etc.).
- **Verifies permissions**: In a CI environment, it checks if the provided token has at least `Developer` role permissions (access level >= 30), which is required to create releases.

### `Prepare`

This step prepares the assets for publishing. It is skipped in `DryRun` mode.

- **Filters assets**: It iterates through the `assets` array and creates a list of valid assets. An asset is considered valid if its `path` exists on the filesystem or if it has a `url`.

### `Publish`

This step creates the GitLab release and attaches the assets. It is skipped in `DryRun` mode.

1.  **Processes assets**: It iterates through the list of valid assets from the `Prepare` step.
    - For assets with a `path`, it uploads the file (or zipped directory) to the GitLab project. It then creates a release link object pointing to the uploaded file.
    - For assets with a `url`, it directly creates a release link object.
2.  **Creates the release**: It sends a request to the GitLab API to create a new release. The payload includes the version number, the release notes, and the array of asset links.

---

## Examples

### Uploading an artifact and linking to a file

```json
{
  "plugins": [
    [
      "@ps-semantic-release/GitLab",
      {
        "assets": [
          {
            "path": "./dist/my-module.zip",
            "label": "PowerShell Module (zip)"
          },
          {
            "url": "https://example.com/some-asset.msi",
            "label": "Windows Installer"
          }
        ]
      }
    ]
  ]
}
```

---

## Logging and Messages

- The plugin logs when it starts and completes each step.
- It provides informative logs when uploading files and creating the release.
- It will throw an error if the environment is not configured correctly (e.g., missing token or insufficient permissions in CI).
- In `DryRun` mode, it logs that the `Publish` step is being skipped.
