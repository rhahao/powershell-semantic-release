function New-ReleaseNotes {
    param ($context)

    $commits = $context.Commits.List
    $releaseRules = [hashtable]@{}

    foreach ($rule in $context.Config.releaseRules) {
        $releaseRules[$rule.type] = @{
            Release = $rule.release
            Section = $rule.section
        }
    }

    $sections = [ordered]@{}

    foreach ($commit in $commits) {
        if (-not $releaseRules.ContainsKey($commit.Type)) {
            continue
        }

        $rule = $releaseRules[$commit.Type]
        $section = $rule.Section

        if (-not $sections.Contains($section)) {
            $sections[$section] = @()
        }

        $sections[$section] += $commit
    }

    if ($sections.Count -eq 0) {
        Add-ConsoleLog "No user facing changes"
        return
    }

    $lines = @()

    $repoUrl = $context.Repository.Url
    $versionPrev = $context.CurrentVersion.Branch
    $versionNext = $context.NextRelease.Version
    $date = Get-Date -Format "yyyy-MM-dd"

    $compareUrl = Get-CompareUrl -RepositoryUrl $repoUrl -FromVersion $versionPrev -ToVersion $versionNext
    $title = ""

    if ($context.NextRelease.Type -eq "patch") {
        $title = "## "
    }
    else {
        $title = "# "
    }
    
    if ($compareUrl) {
        if ($context.DryRun) {
            $title += "$versionNext ($compareUrl) "
        }
        else {

            $title += "[$versionNext]($compareUrl) "
        }
    }
    else {
        $title += "$versionNext "
    }

    $title += "($date)"

    $lines += $title
    $lines += ""

    foreach ($section in $sections.Keys) {
        $lines += "### $section"
        $lines += ""

        foreach ($commit in $sections[$section]) {
            $commitLink = ""

            $link = Get-CommitUrl -RepositoryUrl $repoUrl -Sha $commit.Sha

            if ($link) {
                $shortSha = $commit.Sha.Substring(0, 7)
                $commitLink = " ([$shortSha]($link))"
            }

            $line = ""

            if ($context.DryRun) {
                $line += "    "
            }

            $line += "* **$($commit.Scope):** $($commit.Subject)$commitLink"

            $lines += $line
        }

        $lines += ""
    }

    $notes = $lines -join "`n"

    if ($context.DryRun) {
        Add-ConsoleLog "Release note for version ${versionNext}:`n$notes"
    }

    return $notes
}