# Repository Guidelines

## Project Structure & Module Organization

`PSSemanticRelease/` contains the PowerShell module. Public commands live in
`public/`, internal helpers in `private/`, and bundled release integrations in
`plugins/@ps-semantic-release/`. `PSSemanticRelease.psm1` dot-sources these files
and exports functions from `public/`. Default configuration is under `config/`.
User and contributor documentation lives in `docs/`; keep `SUMMARY.md` aligned
when adding documentation pages. `create-dist.ps1` builds the generated module
package in `dist/`. GitHub Actions workflows are in `.github/workflows/`.

## Build, Test, and Development Commands

- `Import-Module ./PSSemanticRelease -Force` loads the working tree for local
  development. Re-import after changing module files.
- `Invoke-ScriptAnalyzer ./PSSemanticRelease -Recurse -Severity Error` runs the
  same static-analysis gate as CI. Install PSScriptAnalyzer if unavailable.
- `Invoke-Pester ./tests` runs the Pester test suite. Install Pester if unavailable:
  `Install-Module -Name Pester -Force -Scope CurrentUser -MinimumVersion 5.0.0`
- `./create-dist.ps1 -Version 1.2.3` recreates `dist/PSSemanticRelease`, generates
  its manifest, and validates the result.
- `Invoke-SemanticRelease -DryRun` exercises release analysis without publishing.
  Run it from a Git repository after importing the module.

## Coding Style & Naming Conventions

Use four-space indentation in PowerShell, descriptive parameter names, and
approved Verb-Noun names for public functions (for example,
`Invoke-SemanticRelease`). Name one public command per `.ps1` file; keep helper
functions private unless they form part of the supported API. Preserve strict
error handling where release operations can fail. Markdown and JSON follow the
root Prettier configuration: two-space indentation, 80-column wrapping, single
quotes where supported, and ES5 trailing commas. PowerShell files are excluded
from Prettier and must pass PSScriptAnalyzer.

## Testing Guidelines

Pester tests are located in `tests/` and follow the `*.Tests.ps1` naming convention.
The test suite focuses on testing actual business logic and behavior rather than structural validation.
The test suite is organized as follows:
- `tests/Invoke-SemanticRelease.Tests.ps1` - Integration tests for the main public command
- `tests/Config.Tests.ps1` - Tests for branch validation logic
- `tests/Context.Tests.ps1` - Tests for DryRun and CI context behavior
- `tests/GitHelpers.Tests.ps1` - Tests for URL generation and version bumping logic
- `tests/plugins/*.Tests.ps1` - Plugin-specific tests:
  - `CommitAnalyzer.Tests.ps1` - Commit analysis logic and config merging
  - `ReleaseNotesGenerator.Tests.ps1` - Release notes generation behavior
  - `Changelog.Tests.ps1` - Changelog file generation behavior
  - `Git.Tests.ps1` - Git tagging behavior
  - `GitHub.Tests.ps1` - GitHub release validation and DryRun behavior
  - `GitLab.Tests.ps1` - GitLab release validation and DryRun behavior
  - `NuGet.Tests.ps1` - NuGet publishing validation and DryRun behavior
  - `Exec.Tests.ps1` - Custom script execution DryRun behavior

Every change must pass both PSScriptAnalyzer and Pester tests. Run tests locally with
`Invoke-Pester ./tests` (runs all tests) or `Invoke-Pester ./tests/plugins` (runs only plugin tests).
Keep tests isolated from real remotes, registries, and credentials by using mocks. For behavior
changes, also run a dry release and document the repository/configuration used.

## Commit & Pull Request Guidelines

Follow Conventional Commits, including an optional scope: `fix(git): handle
detached HEAD`, `feat(module): add plugin discovery`, or `docs(recipes): update
GitLab example`. Use `!` or a `BREAKING CHANGE:` footer for incompatible changes;
release versions are derived from this history. Pull requests should explain the
motivation and behavior change, link relevant issues, list validation commands,
and update documentation/configuration examples when user-facing behavior
changes. Screenshots are only useful for rendered documentation changes. Never
commit publishing tokens or local `.env` credentials.
