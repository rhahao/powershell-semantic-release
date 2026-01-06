function Get-CurrentSemanticVersion {
    param (
        $context,
        $Branch = "HEAD"
    )

    # 1️⃣ Fetch all tags
    git fetch --tags --quiet

    if ($context.Config.unify_tag) {
        # Use the highest semantic version from all tags
        $lastTag = git tag --list | Sort-Object { [version]($_ -replace '^v', '') } -Descending | Select-Object -First 1
    }
    else {
        # Determine the branch or fallback to HEAD
        if ($Branch -ne 'HEAD') {
            # Check if branch exists locally
            $exists = git show-ref --verify --quiet "refs/heads/$Branch"
            if (-not $exists) {
                & $context.Logger "Fetching branch '$Branch' from origin..."
                git fetch origin "${Branch}:$Branch"
            }
        }

        # Use branch (or HEAD) to get latest tag
        $ref = if ($Branch) { $Branch } else { 'HEAD' }

        # Get last tag reachable from ref
        $lastTag = git describe --tags --abbrev=0 $ref 2>$null
    }

    # Return tag without leading v
    return $lastTag -replace '^v', ''
}
