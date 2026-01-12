$prefix = "[ps-semantic-release]"

function Add-ConsoleLog {
    param ($Message)

    Write-Host "$prefix $Message"
}

function Add-InformationLog {
    param ($Message, $Plugin)

    if ($Plugin) {
        $Plugin = "[$Plugin]"

        Write-Host "$prefix $Plugin i $Message"
    }
    else {
        Write-Host "$prefix i $Message"
    }

}

function Add-SuccessLog {
    param ($Message, $Plugin)

    if ($Plugin) {
        $Plugin = "[$Plugin]"

        Write-Host "$prefix $Plugin v $Message"
    }
    else {
        Write-Host "$prefix v $Message"
    }
}

function Add-WarningLog {
    param ($Message, $Plugin)

    if ($Plugin) {
        $Plugin = "[$Plugin]"

        Write-Host "$prefix $Plugin ! $Message"
    }
    else {
        Write-Host "$prefix ! $Message"
    }
}

function Add-FailureLog {
    param ($Message)

    if ($Plugin) {
        $Plugin = "[$Plugin]"

        Write-Host "$prefix $Plugin x $Message"
    }
    else {
        Write-Host "$prefix x $Message"
    }
}

function Add-FatalLog {
    param ($Message)

    if ($Plugin) {
        $Plugin = "[$Plugin]"

        throw "$prefix $Plugin x $Message"
    }
    else {
        throw "$prefix x $Message"
    }
}