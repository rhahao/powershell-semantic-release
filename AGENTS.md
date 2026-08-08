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

There is currently no committed unit-test suite or coverage threshold. Every
change must pass PSScriptAnalyzer. For behavior changes, run a dry release and
document the repository/configuration used. If adding Pester tests, place them in
`tests/`, name files `*.Tests.ps1`, and keep tests isolated from real remotes,
registries, and credentials.

## Commit & Pull Request Guidelines

Follow Conventional Commits, including an optional scope: `fix(git): handle
detached HEAD`, `feat(module): add plugin discovery`, or `docs(recipes): update
GitLab example`. Use `!` or a `BREAKING CHANGE:` footer for incompatible changes;
release versions are derived from this history. Pull requests should explain the
motivation and behavior change, link relevant issues, list validation commands,
and update documentation/configuration examples when user-facing behavior
changes. Screenshots are only useful for rendered documentation changes. Never
commit publishing tokens or local `.env` credentials.
