function ConvertFrom-Commit {
    param([string]$line)

    $parts = $line -split '\|', 2

    $sha = $parts[0]
    $message = $parts[1]

    $regex = '^(?<type>\w+)(\((?<scope>.+?)\))?(?<breaking>!)?: (?<subject>.+)$'

    if ($message -match $regex) {
        return [PSCustomObject]@{
            Sha      = $sha
            Type     = $matches.type
            Scope    = $matches.scope
            Breaking = [bool]$matches.breaking
            Subject  = $matches.subject
            Message  = $message
        }
    }

    return $null
}

function Expand-ContextString {
    param (
        $context,
        [string]$template
    )

    $pattern = '\{([^}]+)\}'

    return [regex]::Replace(
        $template,
        $pattern,
        [System.Text.RegularExpressions.MatchEvaluator] {
            param($match)

            $path = $match.Groups[1].Value
            $value = $context

            foreach ($segment in $path -split '\.') {
                if ($null -eq $value) {
                    return ''
                }
                $value = $value.$segment
            }

            return [string]$value
        }
    )
}

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
