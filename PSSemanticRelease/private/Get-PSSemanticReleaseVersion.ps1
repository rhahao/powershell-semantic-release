function Get-PSSemanticReleaseVersion {
  $version = Get-Module -Name PSSemanticRelease | Select-Object -ExpandProperty Version
  return $version.ToString()
}
