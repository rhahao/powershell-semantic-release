function Invoke-ReleaseScript {
    param($context)

    if (-not $context.Config.Script) { return }

    if (Get-Command pwsh -ErrorAction SilentlyContinue) {
        pwsh -ExecutionPolicy Bypass -NoProfile -File $context.Config.Script $context.DryRun $context.NextRelease.Version $context.NextRelease.Channel
    }
    elseif (Get-Command powershell -ErrorAction SilentlyContinue) {
        powershell -ExecutionPolicy Bypass -NoProfile -File $context.Config.Script $context.DryRun $context.NextRelease.Version $context.NextRelease.Channel
    }
}