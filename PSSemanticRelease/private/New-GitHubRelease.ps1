function New-GitHubRelease {
    param($context)

    $repo = $context.Repository.Url -replace '^https://github.com/', ''
    $tag = "v$($context.NextRelease.Version)"

    $body = @{
        tag_name   = $tag
        name       = $tag
        body       = $context.NextRelease.Notes
        prerelease = [bool]$context.NextRelease.Channel
        draft      = $false
    } | ConvertTo-Json -Depth 5

    $token = if ($env:GH_TOKEN) { $env:GH_TOKEN } else { $env:GITHUB_TOKEN }

    $headers = @{
        Authorization = "Bearer $token"
        Accept        = "application/vnd.github+json"
        "User-Agent"  = "PSSemanticRelease"
    }

    Invoke-RestMethod `
        -Method Post `
        -Uri "https://api.github.com/repos/$repo/releases" `
        -Headers $headers `
        -Body $body `
        -ContentType "application/json" | Out-Null
}
