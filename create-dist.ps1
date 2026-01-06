param (
    [string]$Version = "0.0.0",
    [string]$Prerelease = $null
)

$moduleName = "PSSemanticRelease"
$distFolder = Join-Path $PSScriptRoot "dist"
$masterPath = Join-Path $PSScriptRoot $moduleName

if (Test-Path $distFolder) {
    Get-ChildItem -Path $distFolder -Recurse | Remove-Item -Recurse -Force
}
else {
    New-Item -Path $distFolder -ItemType Directory | Out-Null
}

$distModuleFolder = "$distFolder/$moduleName"

New-Item -Path $distModuleFolder -ItemType Directory | Out-Null

Get-ChildItem -Path $masterPath | Copy-Item -Destination $distModuleFolder -Recurse

$psd1Path = "$distModuleFolder/$moduleName.psd1"

$names = (Get-ChildItem "$PSScriptRoot/$moduleName/public/*.ps1").BaseName

New-ModuleManifest `
    -Path $psd1Path `
    -RootModule "$moduleName.psm1" `
    -ModuleVersion $Version `
    -Author $env:NUGET_PUBLISHER `
    -FunctionsToExport $names `
    -CmdletsToExport @() `
    -Guid $env:NUGET_PACKAGE_GUID
    
$psd1 = Get-Content $psd1Path -Raw
$psd1 = $psd1 -replace "# ReleaseNotes = ''", "ReleaseNotes = '$Prerelease'"

Set-Content $psd1Path -Value $psd1