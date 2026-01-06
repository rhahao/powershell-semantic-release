function Get-CurrentSemanticVersion {
    param (
        $context,
        $Branch = "HEAD"
    )

    if ($context.Config.unify_tag -and $Branch -eq "main") {
        $lastTag = git tag --list | Sort-Object { [version]($_ -replace '^v', '') } -Descending | Select-Object -First 1
    }
    else {
        $currentBranch = git rev-parse --abbrev-ref $Branch
        $lastTag = git describe --tags --abbrev=0 $currentBranch 2>$null
    }
    
    return $lastTag -replace '^v', ''
}