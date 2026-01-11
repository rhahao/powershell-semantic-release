# Plugins List

**PSSemanticRelease** is built around a plugin system. Each release step is implemented by one or more plugins, allowing the release process to be flexible and extensible.

Plugins are referenced by name in the configuration file and are loaded automatically by **PSSemanticRelease.**

---

## Official plugins

- `@ps-semantic-release/commit-analyzer`
  - `VerifyConditions`: Collect conventional commits since the last release and abort the release if none are found.
  - `AnalyzeCommits`: Determine the next release type (`major`, `minor`, `patch`) based on commit messages and release rules.
- `@ps-semantic-release/ReleaseNotesGenerator`
  - `GenerateNotes`: Generate structured release notes from conventional commits, grouped into sections defined by release rules and sorted by configured commit fields.
- `@ps-semantic-release/Changelog`
  - `VerifyConditions`: Ensure the changelog file path is valid and points to a Markdown file.
  - `Prepare`: Create or update the changelog file with release notes.
- `@ps-semantic-release/Git`
  - `VerifyConditions`: Ensure the Git working tree is clean and Git identity is set.
  - `Prepare`: Stage specified assets, commit changes, and create a Git tag for the release.
  - `Publish`: Push commits and tags to the remote repository.
- `@ps-semantic-release/Exec`
  - `VerifyConditions`: Run a PowerShell script to verify if the release should happen.
  - `AnalyzeCommits`: Run a PowerShell script to determine the type of the next release.
  - `VerifyRelease`: Run a PowerShell script to verify a release before it’s published.
  - `GenerateNotes`: Run a PowerShell script to generate release notes.
  - `Prepare`: Run a PowerShell script to prepare the release (update files, build artifacts, etc.).
  - `publish`: Run a PowerShell script to publish the release.
- `@ps-semantic-release/NuGet`
  - `VerifyConditions`: Check that the NuGet API key is set and that the module path exists.
  - `Prepare`: Update the module manifest (`.psd1`) with the new version and release notes.
  - `Publish`: Publish the module to the configured NuGet repository (default is PSGallery).
- `@ps-semantic-release/GitHub`
  - `VerifyConditions`: Check GitHub token, repository access, and optional CI environment requirements.
  - `Publish`: Create a GitHub release with the new tag, release notes, and optional assets.
- `@ps-semantic-release/GitLab`
  - `VerifyConditions`: Check GitLab token, repository access, and optional CI environment requirements.
  - `Publish`: Create a GitLab release with the new tag and release notes.

---

## Community plugins

Open a Pull Request to add your plugin to the list.
