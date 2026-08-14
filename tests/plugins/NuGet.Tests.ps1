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

Describe "NuGet" {
    Context "VerifyConditions" {
        BeforeEach {
            Mock Add-InformationLog {}
            Mock Add-SuccessLog {}
        }

        It "Should throw when path is missing" {
            $context = [PSCustomObject]@{
                Config = [PSCustomObject]@{
                    Default = [PSCustomObject]@{
                        plugins = @(
                            [PSCustomObject]@{
                                Name = "@ps-semantic-release/NuGet"
                                Config = [PSCustomObject]@{
                                    path = $null
                                    Repository = "PSGallery"
                                }
                            }
                        )
                    }
                    Project = [PSCustomObject]@{
                        plugins = @(
                            [PSCustomObject]@{
                                Name = "@ps-semantic-release/NuGet"
                                Config = [PSCustomObject]@{
                                    path = $null
                                    Repository = "PSGallery"
                                }
                            }
                        )
                    }
                }
                DryRun = $true
            }

            $nuget = [NuGet]::new("@ps-semantic-release/NuGet", $context)
            { $nuget.VerifyConditions() } | Should -Throw
        }

        It "Should throw when non-PSGallery repository lacks source" {
            $context = [PSCustomObject]@{
                Config = [PSCustomObject]@{
                    Default = [PSCustomObject]@{
                        plugins = @(
                            [PSCustomObject]@{
                                Name = "@ps-semantic-release/NuGet"
                                Config = [PSCustomObject]@{
                                    path = "./dist"
                                    Repository = "MyRepo"
                                    Source = $null
                                }
                            }
                        )
                    }
                    Project = [PSCustomObject]@{
                        plugins = @(
                            [PSCustomObject]@{
                                Name = "@ps-semantic-release/NuGet"
                                Config = [PSCustomObject]@{
                                    path = "./dist"
                                    Repository = "MyRepo"
                                    Source = $null
                                }
                            }
                        )
                    }
                }
                DryRun = $false
            }

            $nuget = [NuGet]::new("@ps-semantic-release/NuGet", $context)
            { $nuget.VerifyConditions() } | Should -Throw
        }
    }

    Context "Prepare" {
        BeforeEach {
            Mock Add-InformationLog {}
            Mock Add-SuccessLog {}
            Mock Add-WarningLog {}
        }

        It "Should throw when manifest not found" {
            $context = [PSCustomObject]@{
                DryRun = $true
                Config = [PSCustomObject]@{
                    Default = [PSCustomObject]@{
                        plugins = @(
                            [PSCustomObject]@{
                                Name = "@ps-semantic-release/NuGet"
                                Config = [PSCustomObject]@{
                                    path = "./dist"
                                    Repository = "PSGallery"
                                }
                            }
                        )
                    }
                    Project = [PSCustomObject]@{
                        plugins = @(
                            [PSCustomObject]@{
                                Name = "@ps-semantic-release/NuGet"
                                Config = [PSCustomObject]@{
                                    path = "./dist"
                                    Repository = "PSGallery"
                                }
                            }
                        )
                    }
                }
                NextRelease = [PSCustomObject]@{
                    Notes = "Release notes"
                    Channel = "default"
                }
            }

            $nuget = [NuGet]::new("@ps-semantic-release/NuGet", $context)
            { $nuget.Prepare() } | Should -Throw
        }
    }

    Context "Publish" {
        BeforeEach {
            Mock Add-InformationLog {}
            Mock Add-SuccessLog {}
            Mock Add-WarningLog {}
        }

        It "Should skip in DryRun mode" {
            $context = [PSCustomObject]@{
                DryRun = $true
                Config = [PSCustomObject]@{
                    Default = [PSCustomObject]@{
                        plugins = @(
                            [PSCustomObject]@{
                                Name = "@ps-semantic-release/NuGet"
                                Config = [PSCustomObject]@{
                                    path = "./dist"
                                    Repository = "PSGallery"
                                }
                            }
                        )
                    }
                    Project = [PSCustomObject]@{
                        plugins = @(
                            [PSCustomObject]@{
                                Name = "@ps-semantic-release/NuGet"
                                Config = [PSCustomObject]@{
                                    path = "./dist"
                                    Repository = "PSGallery"
                                }
                            }
                        )
                    }
                }
            }

            $nuget = [NuGet]::new("@ps-semantic-release/NuGet", $context)
            $nuget.Publish()

            Should -Invoke Add-WarningLog -Times 1
        }
    }
}
