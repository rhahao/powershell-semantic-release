function Push-GitAssets {
    param($context)

    $gitConfig = $Context.Config.git

    if (-not $gitConfig) { return }

    $assets = $gitConfig.assets
    $messageTemplate = $gitConfig.message

    if (-not $assets -or -not $messageTemplate) { return }

    $assets = , $assets

    if ($assets.Length -eq 0) { return }

    $lists = @()

    foreach ($asset in $assets) {
        $found = Get-Item -Path $asset -ErrorAction SilentlyContinue

        if (-not $found) { continue }

        $lists += $found.FullName
    }

    if ($lists.Length -eq 0) { return }

    # Stage files
    git add $lists 2>$null

    git restore .
    git restore --staged .

    git add $lists 2>$null

    $commitMessage = Expand-ContextString -context $context -template $messageTemplate

    git commit -m $commitMessage --quiet
    git push origin $Context.Branch --quiet
}
