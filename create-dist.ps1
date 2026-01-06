param (
    [string]$DryRun,
    [string]$Version = "0.0.0",
    [string]$Prerelease = $null
)

try {
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
    $psm1Path = "$distModuleFolder/$moduleName.psm1"

    $names = (Get-ChildItem "$PSScriptRoot/$moduleName/public/*.ps1").BaseName

    New-ModuleManifest `
        -Path $psd1Path `
        -RootModule "$moduleName.psm1" `
        -ModuleVersion $Version `
        -Author $env:NUGET_PUBLISHER `
        -Description "A PowerShell module for automated release using semantic versioning" `
        -FunctionsToExport $names `
        -CmdletsToExport @() `
        -Guid $env:NUGET_PACKAGE_GUID
    
    $psd1 = Get-Content $psd1Path -Raw
    $psd1 = $psd1 -replace "# ReleaseNotes = ''", "ReleaseNotes = '$Prerelease'"

    Set-Content $psd1Path -Value $psd1

    Write-Host "$moduleName.psd1 successfully created."   

    if ($DryRun -like "false") {   
        Set-AuthenticodeSignature -FilePath $psd1Path -Certificate $cert | Out-Null
        Write-Host "$moduleName.psd1 module manifest file signed"

        Set-AuthenticodeSignature -FilePath $psm1Path -Certificate $cert | Out-Null
        Write-Host "$moduleName.psm1 module script file signed"
    
        Publish-Module -Path $distModuleFolder -NuGetApiKey $env:NUGET_API_KEY
        Write-Host "$moduleName published successfully"
    }
}
catch {
    throw $_
}