function Get-CurrentSemanticVersion {
    $currentBranch = git rev-parse --abbrev-ref HEAD

    $lastTag = git describe --tags --abbrev=0 $currentBranch 2>$null

    return $lastTag -replace '^v', ''
}