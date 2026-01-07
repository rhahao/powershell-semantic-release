function New-GitTag {
    param(
        [string]$Version
    )

    git tag "v$Version"
    git push origin "v$Version"
}
