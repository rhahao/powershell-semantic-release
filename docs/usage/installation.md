# Installation

## From PowerShell Gallery

The recommended way to install **PSSemanticRelease** is via the PowerShell Gallery:

```powershell
Install-Module PSSemanticRelease -Scope CurrentUser
```

> Add `-AllowPrerelease` if you want to install prerelease builds:

```powershell
Install-Module PSSemanticRelease -Scope CurrentUser -AllowPrerelease
```

This makes the `Invoke-SemanticRelease` command available in your PowerShell session.

## From Local Source (Development or Latest)

If you’ve cloned the repository or want to test a local version:

```powershell
Import-Module ./PSSemanticRelease -Force
```

This loads the module into your current session directly from the source folder.

## Verify Installation

After installation, verify that **PSSemanticRelease** is loaded:

```powershell
Get-Command Invoke-SemanticRelease
```

You should see output similar to:

```powershell
CommandType     Name                    Version    Source
-----------     ----                    -------    ------
Function        Invoke-SemanticRelease  x.y.z      PSSemanticRelease
```

## System Requirements

**PSSemanticRelease** works with:

- **PowerShell 5.1+** on Windows
- **PowerShell 7+** on all platforms (recommended)
