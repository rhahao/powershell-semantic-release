function Set-GitIdentity {
    $commiterEmail = $env:GIT_AUTHOR_EMAIL

    if ($null -eq $commiterEmail) {
        $commiterEmail = "253679957+ps-semantic-release-bot@users.noreply.github.com"
    }

    $commiterEmail = $env:GIT_AUTHOR_NAME

    if ($null -eq $commiterName) {
        $commiterName = "ps-semantic-release-bot"
    }

    try {
        git config user.email $commiterEmail
        git config user.name $commiterName
    }
    catch {
        throw $_
    }
}