param (
    [string]$DryRun
)

$moduleName = 'PSSemanticRelease'
$distRoot = Join-Path $PSScriptRoot 'dist'
$distPath = Join-Path $distRoot $moduleName

if ($DryRun -like "false") {
    Write-Host "Publishing module to PSGallery"
    Publish-Module  -Path $distPath -NuGetApiKey $env:NUGET_API_KEY -Repository PSGallery
    Write-Host "Publish completed successfully"
}