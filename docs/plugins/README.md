# Plugins

Plugins are the heart of PSSemanticRelease, allowing you to customize and extend the release workflow. Each plugin handles a specific step in the release process, such as analyzing commits, generating release notes, or publishing to a registry.

### Official Plugins

This section provides detailed documentation for each of the official plugins bundled with PSSemanticRelease.

* **[@ps-semantic-release/CommitAnalyzer](./CommitAnalyzer.md)**: Determines the release type from commit messages.
* **[@ps-semantic-release/ReleaseNotesGenerator](./ReleaseNotesGenerator.md)**: Generates changelog content.
* **[@ps-semantic-release/Changelog](./Changelog.md)**: Updates the `CHANGELOG.md` file.
* **[@ps-semantic-release/Git](./git.md)**: Commits, tags, and pushes changes to your repository.
* **[@ps-semantic-release/GitHub](./GitHub.md)**: Creates a GitHub release.
* **[@ps-semantic-release/GitLab](./GitLab.md)**: Creates a GitLab release.
* **[@ps-semantic-release/NuGet](./NuGet.md)**: Publishes your module to a NuGet repository.
* **[@ps-semantic-release/Exec](./Exec.md)**: Executes custom scripts during the release process.
