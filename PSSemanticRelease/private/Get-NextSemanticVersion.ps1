function Get-NextSemanticVersion {
    param (
        [ValidateSet('major', 'minor', 'patch')]
        $Type
    )

    $CurrentVersion = Get-CurrentSemanticVersion
    $v = [version]$CurrentVersion
    $nextVersion = ""

    if ($Type -eq 'major') {
        $nextVersion = "{0}.0.0" -f ($v.Major + 1)
    }
    elseif ($Type -eq 'minor') {
        $nextVersion = "{0}.{1}.0" -f $v.Major, ($v.Minor + 1)
    }
    elseif ($Type -eq 'patch') {
        $nextVersion = "{0}.{1}.{2}" -f $v.Major, $v.Minor, ($v.Build + 1)
    }

    if ($null -eq $CurrentVersion) {
        Write-Host "There is no previous release, the next release version is $nextVersion"
    }
    else {
        Write-Host "The next release version is $nextVersion"
    }

    return $nextVersion
}
