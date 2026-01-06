function Get-ConventionalCommits {
    param($context)

    $Branch = $context.Branch

    $lastTag = git describe --tags --abbrev=0 $Branch 2>$null

    $range = if ($lastTag) { "$lastTag..$Branch" } else { $ref }

    $commits = [System.Collections.Generic.List[object]]::new()
    foreach ($line in git log $range --pretty=format:%s --reverse) {
        $commit = ConvertFrom-Commit $line
        if ($commit) { [void]$commits.Add($commit) }
    }

    return ,$commits.ToArray()
}