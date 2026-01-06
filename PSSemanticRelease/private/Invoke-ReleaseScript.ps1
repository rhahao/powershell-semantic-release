function Invoke-ReleaseScript {
    param($context)

    if (-not $context.Config.Script) { return }

    if (Get-Command pwsh -ErrorAction SilentlyContinue) {
        $psExe = "pwsh"
    }
    elseif (Get-Command powershell -ErrorAction SilentlyContinue) {
        $psExe = "powershell"
    }

    & $psExe -ExecutionPolicy Bypass -NoProfile -File $context.Config.Script
}