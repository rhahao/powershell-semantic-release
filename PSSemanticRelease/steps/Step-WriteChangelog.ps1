function Write-Changelog {
    param($context)

    $changelogPath = "CHANGELOG.md"

    $logs = ""

    if (-not (Test-Path $changelogPath)) {
        Set-Content -Path $changelogPath -Value $logs
        Add-ConsoleLog "Created $changelogPath file"
    }
    else {
        $logs = Get-Content -Path $changelogPath -Raw -Encoding UTF8
    }


    $logs = "$($context.NextRelease.Notes)`n$logs"

    Set-Content -Path $changelogPath -Value $logs -Encoding UTF8
}
