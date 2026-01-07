# PSSemanticRelease (Powershell Semantic Release)

[![PowerShell Gallery](https://img.shields.io/powershellgallery/v/PSSemanticRelease?label=version)](https://www.powershellgallery.com/packages/PSSemanticRelease)

> **Warning:** This module is still a work in progress. APIs and features may change.

---

## Overview

**PSSemanticRelease** is a PowerShell module for automating semantic versioning and releases in a CI/CD workflow.

It helps you:

* Detect the next semantic version based on conventional commits
* Build deterministic module packages
* Validate module manifests and exports

This module is designed for **OSS modules** and focuses on **safe, reproducible releases**.

---

## Installation

Install the prerelease version directly from PSGallery:

```powershell
Install-Module PSSemanticRelease -AllowPrerelease -Force
```

> Note: Use `-AllowPrerelease` to get the latest prerelease builds.

---

## Usage Example

```powershell
Invoke-SemanticRelease
```

---

## Features

* [x] Generate semantic version from conventional commits
* [x] Determine prerelease channels
* [x] Build deterministic module package
* [ ] Full automated publish workflow (work in progress)

---

## Contributing

This project is under active development.

* Feedback, issues, and PRs are welcome
* Follow conventional commits style for versioning

---

## Known Limitations

* Corporate/locked-down machines may restrict module installation
* Signing is currently not implemented
* CI/CD workflow examples are still a work in progress

---
