function Get-ConventionalCommits {
    $lastTag = git describe --tags --abbrev=0 HEAD 2>$null
    $range = if ($lastTag) { "$lastTag..HEAD" } else { "HEAD" }

    $commits = [System.Collections.Generic.List[object]]::new()

    foreach ($line in git log $range --pretty=format:%s) {
        $commit = ConvertFrom-Commit $line
        if ($commit) {
            [void]$commits.Add($commit)
        }
    }

    return ,$commits.ToArray()
}
