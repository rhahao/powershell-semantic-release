function Get-CurrentSemanticVersion {
    param (
        $Branch = "HEAD"
    )
    
    $currentBranch = git rev-parse --abbrev-ref $Branch

    $lastTag = git describe --tags --abbrev=0 $currentBranch 2>$null

    return $lastTag -replace '^v', ''
}