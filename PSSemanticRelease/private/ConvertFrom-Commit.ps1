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
