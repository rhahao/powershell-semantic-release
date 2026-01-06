function Get-NextSemanticVersion {
    param ($context)

    $nextVersion = ""

    if ($null -eq $context.CurrentVersion.Published) {
        $nextVersion = "1.0.0"
    }
    else {
        $v = [version]$context.CurrentVersion.Published
        $Type = $context.NextRelease.Type

        if ($Type -eq 'major') {
            $nextVersion = "{0}.0.0" -f ($v.Major + 1)
        }
        elseif ($Type -eq 'minor') {
            $nextVersion = "{0}.{1}.0" -f $v.Major, ($v.Minor + 1)
        }
        elseif ($Type -eq 'patch') {
            $nextVersion = "{0}.{1}.{2}" -f $v.Major, $v.Minor, ($v.Build + 1)
        }
    }    

    if ($context.NextRelease.Channel -ne "latest" -and -not $context.Config.unify_tag) {
        $tags = git tag | Where-Object { $_ -match "^v$nextVersion-$($context.NextRelease.Channel)\d+$" }

        if (-not $tags) {
            $nextVersion = "$nextVersion-$($context.NextRelease.Channel)1"
        }
        else {
            $last = ($tags | ForEach-Object { [int]($_ -replace ".*-$($context.NextRelease.Channel)", "") } | Sort-Object | Select-Object -Last 1)

            $nextVersion = "$nextVersion-$($context.NextRelease.Channel)$($last + 1)"
        }
    }

    $versionChannel = if ($context.NextRelease.Channel -ne "lastest") { "$($context.NextRelease.Channel) "}
    
    if ($null -eq $context.CurrentVersion.Published) {
        & $context.Logger "There is no previous $($versionChannel)release, the next release version is $nextVersion"
    }
    else {
        & $context.Logger "The next $($versionChannel)release version is $nextVersion"
    }

    return $nextVersion
}
