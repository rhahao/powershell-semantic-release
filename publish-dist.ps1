$distFolder = Join-Path $PSScriptRoot "dist"
$moduleFolder = Join-Path $distFolder "PSSemanticRelease"

Publish-Module -Path $moduleFolder -NuGetApiKey $env:NUGET_API_KEY