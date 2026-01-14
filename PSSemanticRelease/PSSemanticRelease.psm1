Get-ChildItem "$PSScriptRoot/private/*.ps1" | ForEach-Object { . $_ }

Get-ChildItem "$PSScriptRoot/plugins/*/*.ps1" | ForEach-Object { . $_ }

Get-ChildItem "$PSScriptRoot/plugins/Plugins.ps1" | ForEach-Object { . $_ }

Get-ChildItem "$PSScriptRoot/public/*.ps1" | ForEach-Object { . $_ }

Export-ModuleMember -Function (Get-ChildItem "$PSScriptRoot/public/*.ps1").BaseName