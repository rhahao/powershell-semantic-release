param (
    [string]$DryRun,
    [string]$Version = "0.0.0",
    [string]$Prerelease = $null
)

Set-StrictMode -Version Latest

$ErrorActionPreference = 'Stop'

$moduleName = 'PSSemanticRelease'
$srcPath = Join-Path $PSScriptRoot $moduleName
$distRoot = Join-Path $PSScriptRoot 'dist'
$distPath = Join-Path $distRoot $moduleName

Write-Host "Building module $moduleName version $Version"

if (Test-Path $distRoot) {
    Remove-Item $distRoot -Recurse -Force
}

New-Item $distPath -ItemType Directory -Force | Out-Null

Copy-Item "$srcPath\*" $distPath -Recurse -Force

$publicPath = Join-Path $srcPath 'public'

$functions = if (Test-Path $publicPath) {
    Get-ChildItem $publicPath -Filter '*.ps1' | Select-Object -ExpandProperty BaseName
}
else {
    @()
}

$psd1Path = Join-Path $distPath "$moduleName.psd1"

New-ModuleManifest `
    -Path $psd1Path `
    -RootModule "$moduleName.psm1" `
    -ModuleVersion $Version `
    -Author $env:NUGET_PUBLISHER `
    -Description 'A PowerShell module for automated release using semantic versioning' `
    -FunctionsToExport $functions `
    -CmdletsToExport @() `
    -VariablesToExport @() `
    -AliasesToExport @() `
    -Guid $env:NUGET_PACKAGE_GUID `
    -ReleaseNotes $Prerelease

Test-ModuleManifest $psd1Path | Out-Null
Write-Host "Module created and manifest validated"

if ($DryRun -like "false") {
    Write-Host "Publishing module to PSGallery"
    Publish-Module  -Path $distPath -NuGetApiKey $env:NUGET_API_KEY -Repository PSGallery
    Write-Host "Publish completed successfully"
}