function Get-CurrentSemanticVersion {
    param (
        $context,
        $Branch = "HEAD"
    )

    git fetch --tags --quiet

    if ($context.Config.unify_tag) {
        $lastTag = git tag --list | Sort-Object { [version]($_ -replace '^v', '') } -Descending | Select-Object -First 1
    }
    else {
        if ($Branch -eq 'main' -and $context.Branch -ne "main") {
            $exists = git show-ref --verify --quiet "refs/heads/$Branch"

            if (-not $exists) {
                git fetch origin "${Branch}:$Branch" --quiet
            }
        }

        $ref = if ($Branch) { $Branch } else { 'HEAD' }

        $lastTag = git describe --tags --abbrev=0 $ref 2>$null
    }

    return $lastTag -replace '^v', ''
}