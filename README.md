# PSSemanticRelease (PowerShell Semantic Release)

Fully automated version management and release workflow for PowerShell modules. Inspired by the popular [semantic-release](https://github.com/semantic-release/semantic-release), **PSSemanticRelease** automates version determination, changelog generation, Git tagging, and optional publishing to GitHub, GitLab, and module registries.

[![PowerShell Gallery](https://img.shields.io/powershellgallery/v/PSSemanticRelease?label=version)](https://www.powershellgallery.com/packages/PSSemanticRelease)

---

## Key Features

- **Automatic semantic versioning** based on commit messages.
- **Changelog and release notes generation**.
- **Git tagging** and optional **GitHub/GitLab release** creation.
- **Publish modules** to PSGallery or NuGet.
- **DryRun mode** for safe testing without impacting your repository.
- **Extensible architecture** via plugins and custom scripts.

---

## How It Works

**PSSemanticRelease** inspects your commit messages to determine how to bump the version—**major**, **minor**, or **patch**—following semantic versioning rules. By default, it uses the [Conventional Commits](https://www.conventionalcommits.org/) specification.

| Commit message                                      | Release type                    |
| --------------------------------------------------- | ------------------------------- |
| `fix(parser): handle multi-line comments correctly` | Patch release                   |
| `feat(cli): add --verbose flag to Get-ModuleInfo`   | Minor release                   |
| `refactor(build): simplify release script logic`    | _no release_                    |
| `feat(api)!: remove deprecated Invoke-OldCommand`   | Major release (breaking change) |

---

## Extensible with Plugins

The real power of **PSSemanticRelease** lies in its extensibility. The release workflow is a series of steps, and each step is handled by one or more plugins. You can customize the entire process by adding or removing plugins in your `semantic-release.json` configuration file.

### Core Plugins

**PSSemanticRelease** ships with a suite of official plugins to handle the most common release tasks:

| Plugin                  | Description                                                              |
| ----------------------- | ------------------------------------------------------------------------ |
| **CommitAnalyzer**      | Determines the release type (major, minor, patch) from commit messages.  |
| **ReleaseNotesGenerator** | Generates changelog content from the analyzed commits.                   |
| **Changelog**           | Updates the `CHANGELOG.md` file with the new release notes.              |
| **Git**                 | Commits changes, creates Git tags, and pushes to your remote repository. |
| **GitHub** / **GitLab** | Creates a release on GitHub or GitLab, including release notes.          |
| **NuGet**               | Publishes your PowerShell module to a NuGet-based repository.            |
| **Exec**                | Allows you to run custom scripts at any stage of the release process.    |

> For detailed plugin configuration, see the [Plugins documentation](./docs/usage/plugins.md).

---

## Release Flow

A **PSSemanticRelease** run goes through the following phases, executed by the configured plugins:

| Step               | Description                                                                                |
| ------------------ | ------------------------------------------------------------------------------------------ |
| `VerifyConditions` | Checks that your environment, credentials, and configuration are valid.                    |
| `AnalyzeCommits`   | Scans commits to determine the next release type.                                          |
| `VerifyRelease`    | Optional validations to ensure the release can proceed safely.                             |
| `GenerateNotes`    | Generates release notes from commit history.                                               |
| `Prepare`          | Updates module manifests, changelogs, or runs preparation scripts.                         |
| `Publish`          | Creates Git tags, pushes commits, and publishes artifacts.                                 |

> This workflow mirrors the official [semantic-release](https://semantic-release.gitbook.io/semantic-release/#release-steps) pipeline.

---

## Getting Started

Ready to automate your releases?

1.  **[Installation](./docs/usage/installation.md)**: Add **PSSemanticRelease** to your project.
2.  **[Configuration](./docs/usage/configuration.md)**: Create your `semantic-release.json` file.
3.  **[CI Setup](./docs/usage/ci-configuration.md)**: Integrate it into your CI/CD pipeline (e.g., GitHub Actions).

