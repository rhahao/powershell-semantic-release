function Resolve-RepositoryUrl {
    param ([string]$Url)

    if ($Url -match '^git@([^:]+):(.+?)(\.git)?$') {
        return "https://$($matches[1])/$($matches[2])"
    }

    if ($Url -match '^https?://.+?/.+?') {
        return $Url -replace '\.git$', ''
    }

    return $null
}
