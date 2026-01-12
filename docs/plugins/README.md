# Plugins List

**PSSemanticRelease** is built around a plugin system. Each release step is implemented by one or more plugins, allowing the release process to be flexible and extensible.

Plugins are referenced by name in the configuration file and are loaded automatically by **PSSemanticRelease.**

---

## Official plugins

- [@ps-semantic-release/commit-analyzer](./official/CommitAnalyzer.md)
- @ps-semantic-release/ReleaseNotesGenerator
- @ps-semantic-release/Changelog
- @ps-semantic-release/Git
- @ps-semantic-release/Exec
- [@ps-semantic-release/NuGet](./official/NuGet.md)
- @ps-semantic-release/GitHub
- @ps-semantic-release/GitLab

---

## Community plugins

Open a Pull Request to add your plugin to the list.
