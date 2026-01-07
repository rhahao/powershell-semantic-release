function Get-PSSemanticReleaseVersion {
  $version = Get-Module -Name PSSemanticRelease | Select-Object -First 1 -ExpandProperty Version
  return $version.ToString()
}
