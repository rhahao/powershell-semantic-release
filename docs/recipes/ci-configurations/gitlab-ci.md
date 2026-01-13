# GitLab CI/CD

Here is a basic recipe for integrating `PSSemanticRelease` into a GitLab CI/CD pipeline.

## Basic `.gitlab-ci.yml`

This example sets up a single `release` stage that runs on the `main` branch. The `@ps-semantic-release/GitLab` plugin will automatically use GitLab's predefined `CI_JOB_TOKEN` for authentication.

```yaml
stages:
  - release

release_job:
  stage: release
  image: mcr.microsoft.com/powershell:latest # Use an image with PowerShell
  variables:
    # Optional: Add NUGET_API_KEY as a masked CI/CD variable in project settings if needed
    # NUGET_API_KEY: $YOUR_NUGET_KEY
  script:
    - pwsh -c "Install-Module PSSemanticRelease -Force"
    - pwsh -c "Invoke-SemanticRelease"
  rules:
    # Run only on the main branch
    - if: '$CI_COMMIT_BRANCH == "main"'
      when: on_success
```

---

## Automatic Authentication with `CI_JOB_TOKEN`

The `@ps-semantic-release/GitLab` plugin is designed to work seamlessly with GitLab CI/CD.

It automatically detects and uses the predefined `CI_JOB_TOKEN` environment variable for authenticating to the GitLab API. You do not need to manually assign it to any other variable.

As long as the user who triggers the pipeline has the **Developer** role (or higher) in the project, the token will have sufficient permissions to create a GitLab Release.

## Publishing to NuGet

If you use the `@ps-semantic-release/NuGet` plugin, you will need to provide an API key.

1.  In your GitLab project, go to **Settings > CI/CD** and expand the **Variables** section.
2.  Add a variable named `NUGET_API_KEY`.
3.  Paste your NuGet API key into the value field.
4.  **Important:** Select the **Mask variable** option to prevent the key from being exposed in job logs.
5.  If you defined the variable in your YAML, uncomment the `NUGET_API_KEY` line in your `.gitlab-ci.yml` file.
