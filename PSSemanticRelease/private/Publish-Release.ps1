function Publish-Release {
    param($Context)

    if ($Context.DryRun) {
        Add-ConsoleLog "Dry-run: release not published"
        return
    }

    $provider = Get-ReleaseProvider

    if ($null -eq $provider) {
        Add-ConsoleLog "creating release aborted on unsupported CI provider"
        return
    }

    if ($provider -eq "github") {
        New-GitHubRelease -context $context
    }

    if ($provider -eq "gitlab") {
        New-GitLabRelease -context $context
    }

    Add-ConsoleLog "Published release $($context.NextRelease.Version) on $($context.NextRelease.Channel) channel"
}
