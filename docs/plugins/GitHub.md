# @ps-semantic-release/GitHub

A plugin that publishes releases to GitHub. It handles file uploads and creates a GitHub Release with the generated release notes.

---

## Configuration

- `assets`:
  - **Type:** array of objects
  - **Required:** no
  - **Default:** none
  - **Description:** A list of assets to upload to the GitHub release. Each asset is an object that can have the following properties:
    - `path`: The path to the file or directory to upload. If a directory is provided, it will be compressed into a `.zip` file before uploading.
    - `name`: An optional name for the uploaded asset. You can use placeholders like `{NextRelease.Version}`.
    - `label`: An optional label for the asset, which will be displayed on the release page.

---

## Behavior details

### `VerifyConditions`

This step ensures that the plugin is running in a valid environment.

- **Validates `assets`**: Checks that the `assets` configuration is an array, if provided.
- **Checks CI environment**: If running in a CI environment, it verifies that:
  - It is running in a GitHub Actions workflow.
  - A `GITHUB_TOKEN` or `GH_TOKEN` is available.
- **Determines GitHub URLs**: It automatically determines the correct GitHub API and server URLs, which is useful for GitHub Enterprise users.
- **Verifies permissions**: In a CI environment, it will test if it has permissions to create a GitHub release.

### `Prepare`

This step prepares the assets for upload.

- **Filters assets**: It iterates through the `assets` array and creates a list of valid assets where the `path` exists on the filesystem.

### `Publish`

This step creates the GitHub release and uploads the assets. It is skipped in `DryRun` mode.

1.  **Creates the release**: It sends a request to the GitHub API to create a new release, using the version number as the tag name and the release notes as the body.
2.  **Uploads assets**: If any valid assets were found in the `Prepare` step, it uploads them to the newly created release. 
    - If an asset `path` points to a directory, it is first compressed into a `.zip` file.

---

## Examples

### Uploading a build artifact

This configuration will find the `my-module.zip` file in the `dist` directory and upload it with the label "My PowerShell Module".

```json
{
  "plugins": [
    [
      "@ps-semantic-release/GitHub",
      {
        "assets": [
          {
            "path": "./dist/my-module.zip",
            "label": "My PowerShell Module"
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
- It provides informative logs about the release creation and asset uploads.
- It will throw an error if the environment is not configured correctly (e.g., missing token in CI).
- In `DryRun` mode, it logs that the `Publish` step is being skipped.
