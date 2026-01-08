function Test-GitTagExist {
    param ([string]$tag)

    git rev-parse -q --verify "refs/tags/$tag" *> $null
    return $LASTEXITCODE -eq 0
}
