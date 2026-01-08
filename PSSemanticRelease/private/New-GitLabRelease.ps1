function New-GitLabRelease {
    param($context)

    $projectId = [uri]::EscapeDataString(
        $context.Repository.Url -replace '^https://gitlab.com/', ''
    )

    $tag = "v$($context.NextRelease.Version)"

    $body = @{
        name        = $tag
        tag_name    = $tag
        description = $context.NextRelease.Notes
    }

    Invoke-RestMethod `
        -Method Post `
        -Uri "https://gitlab.com/api/v4/projects/$projectId/releases" `
        -Headers @{ "PRIVATE-TOKEN" = $env:GITLAB_TOKEN } `
        -Body $body
}
