function ConvertFrom-Commit {
  param([string]$Message)

  $regex = '^(?<type>\w+)(\((?<scope>.+?)\))?(?<breaking>!)?: (?<subject>.+)$'

  if ($Message -match $regex) {
    return [PSCustomObject]@{
      Type      = $matches.type
      Scope     = $matches.scope
      Breaking  = [bool]$matches.breaking
      Subject   = $matches.subject
      Message   = $Message
    }
  }

  return $null
}
