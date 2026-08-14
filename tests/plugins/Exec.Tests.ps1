BeforeAll {
    $modulePath = Join-Path $PSScriptRoot "../../PSSemanticRelease"
    Import-Module $modulePath -Force

    # Dot-source private scripts to access internal functions for testing
    Get-ChildItem "$modulePath/private/*.ps1" | ForEach-Object { . $_ }
    Get-ChildItem "$modulePath/plugins/@ps-semantic-release/*.ps1" | ForEach-Object { . $_ }
}

AfterAll {
    Remove-Module PSSemanticRelease -Force -ErrorAction SilentlyContinue
}

Describe "Exec" {
    Context "Publish" {
        BeforeEach {
            Mock Add-InformationLog {}
            Mock Add-SuccessLog {}
        }

        It "Should skip in DryRun mode when script configured" {
            $context = [PSCustomObject]@{
                Config = [PSCustomObject]@{
                    Default = [PSCustomObject]@{
                        plugins = @(
                            [PSCustomObject]@{
                                Name = "@ps-semantic-release/Exec"
                                Config = [PSCustomObject]@{
                                    publishPsScript = "./script.ps1"
                                }
                            }
                        )
                    }
                    Project = [PSCustomObject]@{
                        plugins = @(
                            [PSCustomObject]@{
                                Name = "@ps-semantic-release/Exec"
                                Config = [PSCustomObject]@{
                                    publishPsScript = "./script.ps1"
                                }
                            }
                        )
                    }
                }
                DryRun = $true
            }

            Mock Add-WarningLog {}

            $exec = [Exec]::new("@ps-semantic-release/Exec", $context)
            $exec.Publish()

            Should -Invoke Add-WarningLog -Times 1
        }
    }
}
