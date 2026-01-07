function Get-ConventionalCommits {
    param($context)

    $Branch = $context.Branch

    $lastTag = git describe --tags --abbrev=0 $Branch 2>$null

    $range = if ($lastTag) { "$lastTag..$Branch" } else { $Branch }

    $commits = @()
    foreach ($line in git log $range --pretty=format:%s --reverse) {
        $commit = ConvertFrom-Commit $line
        if ($commit) { $commits += $commit }
    }

    return , $commits
}