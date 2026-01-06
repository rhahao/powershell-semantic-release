function Get-ConventionalCommits {
    param($context)

    $Branch = $context.Branch

    if ($Branch) {
        $localBranchExists = git show-ref --verify --quiet "refs/heads/$Branch"
        if (-not $localBranchExists) {
            git fetch origin "${Branch}:$Branch" --quiet
        }
    }

    $ref = if ($Branch) { $Branch } else { 'HEAD' }

    $lastTag = git describe --tags --abbrev=0 $ref 2>$null

    $range = if ($lastTag) { "$lastTag..$ref" } else { $ref }

    $commits = [System.Collections.Generic.List[object]]::new()

    foreach ($line in git log $range --pretty=format:%s --reverse) {
        $commit = ConvertFrom-Commit $line
        if ($commit) {
            [void]$commits.Add($commit)
        }
    }

    return ,$commits.ToArray()
}
