# PSSemanticRelease (Powershell Semantic Release)

Fully automated version management and release workflow for PowerShell modules. Inspired by the popular [semantic-release](https://github.com/semantic-release/semantic-release) project, PSSemanticRelease automates version determination, changelog generation, tagging, and optional publishing.

[![PowerShell Gallery](https://img.shields.io/powershellgallery/v/PSSemanticRelease?label=version)](https://www.powershellgallery.com/packages/PSSemanticRelease)

---

## Highlights

- Automated semantic versioning from commit messages
- Generate release notes and changelogs automatically
- Git tagging and optional GitHub / GitLab release support
- Publish PowerShell modules to PSGallery / NuGet
- DryRun mode for safe testing before real release
- Extensible via plugins and custom scripts

---

## How It Works

PSSemanticRelease uses your commit messages to determine how the version should be bumped — major, minor, or patch — following semantic versioning rules. It analyzes commits, generates release notes, updates changelogs, creates Git tags, and can publish to GitHub/GitLab and module registries.

By default, it relies on conventional commit formats like:

| Commit message                                                       | Release type                    |
| -------------------------------------------------------------------- | ------------------------------- |
| `fix(pencil): stop graphite breaking when too much pressure applied` | Patch release                   |
| `feat(pencil): add 'graphiteWidth' option`                           | Minor release                   |
| `perf(pencil): remove graphiteWidth option`                          | _none_                          |
| `feat(pencil)!: The graphiteWidth option has been removed.`          | Major release (Breaking change) |

---

## Release steps

A `PSSemanticRelease` run includes the following phases:

| Step               | Description                                          |
| ------------------ | ---------------------------------------------------- |
| `VerifyConditions` | Ensure the environment and configuration are correct |
| `AnalyzeCommits`   | Determine next release type from commits             |
| `VerifyRelease`    | Optional additional checks                           |
| `GenerateNotes`    | Create release notes from commit history             |
| `Prepare`          | Update changelogs, manifests, and run custom scripts |
| `Publish`          | Commit & tag in Git and publish artifacts            |

This flow mirrors the official [semantic‑release](https://semantic-release.gitbook.io/semantic-release/#release-steps) pipeline.

---

## Prerequisites

To use `PSSemanticRelease` effectively:

- A Git repository hosting your code
- A CI service such as GitHub Actions, GitLab CI, or others
- Proper credentials/tokens in environment variables for publishing (e.g., GITHUB_TOKEN, NUGET_API_KEY)
- Conventional commit discipline in your team
