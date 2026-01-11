function Test-CIEnvironment {
    if ($env:GITHUB_ACTIONS -eq "true") {
        return $true
    }

    if ($env:GITLAB_CI -eq "true") {
        return $true
    }
  
    return $false
}

function Get-PSSemanticReleaseVersion {
    $version = Get-Module -Name PSSemanticRelease | Select-Object -First 1 -ExpandProperty Version
    return $version.ToString()
}

function Get-EnvFromFile {
    $file = ".env"

    if (-not (Test-Path $file)) { return }

    $lines = Get-Content -Path $file

    foreach ($line in $lines) {
        $line = $line.Trim()

        if (-not $line -or $line.StartsWith("#")) { continue }

        $parts = $line -split "=", 2

        if ($parts.Count -lt 2) { continue }

        $name = $parts[0].Trim()
        $value = $parts[1].Trim()

        if (($value.StartsWith('"') -and $value.EndsWith('"')) -or
            ($value.StartsWith("'") -and $value.EndsWith("'"))) {
            $value = $value.Substring(1, $value.Length - 2)
        }

        [Environment]::SetEnvironmentVariable($name, $value, "Process")
    }
}