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

function Format-SortCommits {
    param(
        [object[]]$Commits,
        [string[]]$SortKeys
    )

    if (-not $SortKeys -or $SortKeys.Count -eq 0) {
        return $Commits
    }

    $properties = foreach ($key in $SortKeys) {
        @{
            Expression = [ScriptBlock]::Create("`$_.$key")
            Ascending  = $true
        }
    }

    return $Commits | Sort-Object -Property $properties
}

function Get-BaseSemanticVersion {
    param([string]$Version)

    if (-not $Version) { return $null }

    $base = $Version -replace '-.*$', ''

    try {
        return [version]$base
    }
    catch {
        return $null
    }
}

function Format-ReleaseNotesDryRun {
    param ($notes)

    $draftNotes = @()

    foreach ($note in $notes -split "`n") {
        $line = $note

        if ($note -match '^(#{1,2}) \[(.+)\]\([^)]+\)(.*)') {
            $hashes = $Matches[1]
            $version = $Matches[2]
            $suffix = $Matches[3]
            $line = "$hashes $version$suffix"
        }
        elseif ($note -match '^\* ') {
            $line = $note -replace '\*\*', ''
            $line = $line -replace '\(\[[^\]]+\]\((https?://[^)]+)\)\)', '($1)'
            $line = "    $line"
        }

        $draftNotes += $line
    }

    return $draftNotes -join "`n"
}

function Format-ReleaseBranchesList {
    param($branches)

    $list = @()

    foreach ($b in $branches) {
        if ($b -is [string]) {
            $list += $b
        }
        else {
            $list += $b.name
        }
    }

    return $list
}