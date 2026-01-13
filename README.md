# PSSemanticRelease (PowerShell Semantic Release)

Fully automated version management and release workflow for PowerShell modules. Inspired by the popular [semantic-release](https://github.com/semantic-release/semantic-release), **PSSemanticRelease** automates version determination, changelog generation, Git tagging, and optional publishing to GitHub, GitLab, and module registries.

[![PowerShell Gallery](https://img.shields.io/powershellgallery/v/PSSemanticRelease?label=version)](https://www.powershellgallery.com/packages/PSSemanticRelease)

---

## Key Features

- **Automatic semantic versioning** based on commit messages
- **Changelog and release notes generation**
- **Git tagging** and optional **GitHub/GitLab release** creation
- **Publish modules** to PSGallery or NuGet
- **DryRun mode** for safe testing without affecting your repo
- **Extensible architecture** via plugins and custom scripts

---

## How It Works

**PSSemanticRelease** inspects your commit messages to determine how to bump the version—**major**, **minor**, or **patch**—following semantic versioning rules.

It then:

1. Analyzes commits for meaningful changes
2. Generates release notes and updates changelogs
3. Creates Git tags
4. Publishes modules to your chosen registry (optional)
5. Can also create releases on GitHub or GitLab

By default, it uses conventional commit formats:

| Commit message                                      | Release type                    |
| --------------------------------------------------- | ------------------------------- |
| `fix(parser): handle multi-line comments correctly` | Patch release                   |
| `feat(cli): add --verbose flag to Get-ModuleInfo`   | Minor release                   |
| `refactor(build): simplify release script logic`    | _no release_                    |
| `feat(api)!: remove deprecated Invoke-OldCommand`   | Major release (breaking change) |

---

## Release Flow

A **PSSemanticRelease** run goes through the following phases:

| Step               | Description                                                                                |
| ------------------ | ------------------------------------------------------------------------------------------ |
| `VerifyConditions` | Checks that your environment, credentials, and configuration are valid.                    |
| `AnalyzeCommits`   | Scans commits to determine the next release type (patch, minor, major).                    |
| `VerifyRelease`    | Optional validations to ensure the release can proceed safely.                             |
| `GenerateNotes`    | Generates release notes and changelog content from commit history.                         |
| `Prepare`          | Updates module manifests, changelogs, compresses assets, or runs preparation scripts.      |
| `Publish`          | Creates Git tags, pushes commits, and publishes artifacts (NuGet/PSGallery/GitHub/GitLab). |

> This workflow mirrors the official [semantic‑release](https://semantic-release.gitbook.io/semantic-release/#release-steps) pipeline.

---

## Prerequisites

Before using **PSSemanticRelease**, ensure:

- Your code is in a **Git repository**
- You are running in a **CI environment** (GitHub Actions, GitLab CI, etc.)
- Required tokens/credentials are set as environment variables (e.g., `GITHUB_TOKEN`, `NUGET_API_KEY`)
- Your team follows **conventional commit discipline**

---

## Next Steps

For more details on:

- **Plugins and customization**
- **Release notes generation**
- **Publishing targets (GitHub, GitLab, NuGet, PSGallery)**

Please refer to the dedicated pages in this documentation.
