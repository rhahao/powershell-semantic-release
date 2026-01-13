# Using PSSemanticRelease with GitHub Actions

## Environment variables

To run **PSSemanticRelease** in GitHub Actions, you need environment variables for Git and optionally for NuGet publishing:

| Variable                     | Description                                                                                                                                         |
| ---------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| `GITHUB_TOKEN` or `GH_TOKEN` | Personal access token or automatically populated token for GitHub repository access. Used to push tags, create releases, and comment on PRs/issues. |
| `NUGET_API_KEY`              | Required if publishing a PowerShell module to a NuGet repository (e.g., PSGallery).                                                                 |

These variables should be configured as **GitHub Secrets.**

## CI Pipeline Requirements

- Run **PSSemanticRelease** only after all tests succeed.
- Ensure the branch triggering the release is correct (usually `main`).
- Fetch the full Git history (`fetch-depth: 0`) so that commit analysis works correctly.

## Minimal Workflow Example

```yml
name: Release
on:
  push:
    branches:
      - main

permissions:
  contents: read

jobs:
  release:
    name: Release
    runs-on: ubuntu-latest
    permissions:
      contents: write # for creating Git tags and releases

    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          fetch-depth: 0
          ref: ${{ github.head_ref }}
          persist-credentials: true

      - name: Install dependencies
        shell: pwsh
        run: Install-Module PSSemanticRelease -Scope CurrentUser -Force

      - name: Release
        shell: pwsh
        run: Invoke-SemanticRelease
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          NUGET_API_KEY: ${{ secrets.NUGET_API_KEY }} # optional
```

## Optional: Pushing module changes automatically

If you want **PSSemanticRelease** to update files like the module manifest or changelog automatically:

- Use the `@ps-semantic-release/Git` plugin.
- Make sure the GitHub token has write access.
- For branch-protected repositories, a **Personal Access Token is required** instead of the automatically populated `GITHUB_TOKEN`.
