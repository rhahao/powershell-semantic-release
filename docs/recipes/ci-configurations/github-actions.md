# GitHub Actions

Here is a basic recipe for integrating `PSSemanticRelease` into a GitHub Actions workflow.

## Basic `release.yml` Workflow

This example sets up a single `release` job that runs on pushes to the `main` branch. Create this file at `.github/workflows/release.yml`.

```yaml
name: Release

on:
  push:
    branches:
      - main

jobs:
  release:
    name: Release
    runs-on: ubuntu-latest
    permissions:
      contents: write # Required to create a GitHub release and push commits

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Install PSSemanticRelease
        shell: pwsh
        run: Install-Module PSSemanticRelease -Scope CurrentUser -Force

      - name: Run Semantic Release
        shell: pwsh
        run: Invoke-SemanticRelease
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          # Optional: Add NUGET_API_KEY as a secret in repository settings
          # NUGET_API_KEY: ${{ secrets.NUGET_API_KEY }}
```

---

## Authentication with `GITHUB_TOKEN`

The `@ps-semantic-release/github` plugin requires a token to publish a release. The easiest way to provide this is by using the `GITHUB_TOKEN` secret that is automatically available in every GitHub Actions workflow.

### 1. Granting Permissions

For the token to have sufficient permission to create a release, you must add the `permissions` key to your job or workflow:

```yaml
permissions:
  contents: write
```

This grants the `GITHUB_TOKEN` the necessary permissions to create Git tags and publish GitHub Releases for your repository.

### 2. Passing the Token

The token must be passed to your script as an environment variable. The plugin will automatically look for `GITHUB_TOKEN` or `GH_TOKEN`.

```yaml
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

## Publishing to NuGet

If you use the `@ps-semantic-release/nuget` plugin, you will need to provide an API key as a secret.

1.  In your GitHub repository, go to **Settings > Secrets and variables > Actions**.
2.  Click **New repository secret**.
3.  Create a secret named `NUGET_API_KEY` and paste your NuGet API key into the value field.
4.  Uncomment the `NUGET_API_KEY` line in your `release.yml` file to make the secret available to your script.
