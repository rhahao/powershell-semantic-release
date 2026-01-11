$prefix = "[ps-semantic-release] ›"

function Add-ConsoleLog {
    param ($Message)

    Write-Host "$prefix $Message"
}

function Add-InformationLog {
    param ($Message, $Plugin)

    if ($Plugin) {
        $Plugin = "[$Plugin]"

        Write-Host "$prefix $Plugin › ℹ $Message"
    } else {
        Write-Host "$prefix ℹ $Message"
    }

}

function Add-SuccessLog {
    param ($Message, $Plugin)

    if ($Plugin) {
        $Plugin = "[$Plugin]"

        Write-Host "$prefix $Plugin › ✔ $Message"
    } else {
        Write-Host "$prefix ✔ $Message"
    }
}

function Add-WarningLog {
    param ($Message, $Plugin)

    if ($Plugin) {
        $Plugin = "[$Plugin]"

        Write-Host "$prefix $Plugin › ⚠ $Message"
    } else {
        Write-Host "$prefix ⚠ $Message"
    }
}

function Add-FailureLog {
    param ($Message)

    if ($Plugin) {
        $Plugin = "[$Plugin]"

        Write-Host "$prefix $Plugin › ✘ $Message"
    } else {
        Write-Host "$prefix ✘ $Message"
    }
}
