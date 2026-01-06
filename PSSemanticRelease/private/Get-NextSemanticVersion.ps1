function Get-NextSemanticVersion {
    param (
        [ValidateSet('major', 'minor', 'patch')]
        $Type,
        $BaseVersion,
        $BranchVersion,
        $Channel
    )

    $nextVersion = ""

    if ($null -eq $BaseVersion) {
        $nextVersion = "1.0.0"
    }
    else {
        $v = [version]$BaseVersion

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

    if ($Channel -ne "latest") {
        $tags = git tag | Where-Object { $_ -match "^v$nextVersion-$Channel\.\d+$" }

        if (-not $tags) {
            $nextVersion = "$nextVersion-$Channel.1"
        }
        else {
            $last = ($tags | ForEach-Object { [int]($_ -replace ".*-$Channel\.", "") } | Sort-Object | Select-Object -Last 1)

            $nextVersion = "$nextVersion-$Channel.$($last + 1)"
        }
    }

    $versionChannel = if ($Channel -ne "lastest") { "$Channel "}
    if ($null -eq $BaseVersion) {
        Write-Host "There is no previous $($versionChannel)release, the next $($versionChannel)release version is $nextVersion"
    }
    else {
        Write-Host "The next $($versionChannel)release version is $nextVersion"
    }

    return $nextVersion
}
