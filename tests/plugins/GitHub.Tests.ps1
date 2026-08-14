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

Describe "GitHub" {
    Context "VerifyConditions" {
        BeforeEach {
            Mock Add-InformationLog {}
            Mock Add-SuccessLog {}
        }

        It "Should skip permission test when not in CI" {
            $context = [PSCustomObject]@{
                Config = [PSCustomObject]@{
                    Default = [PSCustomObject]@{
                        plugins = @(
                            [PSCustomObject]@{
                                Name = "@ps-semantic-release/GitHub"
                                Config = [PSCustomObject]@{}
                            }
                        )
                    }
                    Project = [PSCustomObject]@{
                        plugins = @(
                            [PSCustomObject]@{
                                Name = "@ps-semantic-release/GitHub"
                                Config = [PSCustomObject]@{}
                            }
                        )
                    }
                }
                EnvCI = [PSCustomObject]@{
                    IsCI = $false
                    Token = $null
                }
                Repository = [PSCustomObject]@{
                    Url = "https://github.com/user/repo"
                }
            }

            $github = [GitHub]::new("@ps-semantic-release/GitHub", $context)
            { $github.VerifyConditions() } | Should -Not -Throw
        }

        It "Should throw when assets is not an array" {
            $context = [PSCustomObject]@{
                Config = [PSCustomObject]@{
                    Default = [PSCustomObject]@{
                        plugins = @(
                            [PSCustomObject]@{
                                Name = "@ps-semantic-release/GitHub"
                                Config = [PSCustomObject]@{
                                    assets = "invalid"
                                }
                            }
                        )
                    }
                    Project = [PSCustomObject]@{
                        plugins = @(
                            [PSCustomObject]@{
                                Name = "@ps-semantic-release/GitHub"
                                Config = [PSCustomObject]@{
                                    assets = "invalid"
                                }
                            }
                        )
                    }
                }
                EnvCI = [PSCustomObject]@{
                    IsCI = $false
                    Token = $null
                }
                Repository = [PSCustomObject]@{
                    Url = "https://github.com/user/repo"
                }
            }

            $github = [GitHub]::new("@ps-semantic-release/GitHub", $context)
            { $github.VerifyConditions() } | Should -Throw
        }
    }

    Context "Prepare" {
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
                                Name = "@ps-semantic-release/GitHub"
                                Config = [PSCustomObject]@{
                                    assets = @()
                                }
                            }
                        )
                    }
                    Project = [PSCustomObject]@{
                        plugins = @(
                            [PSCustomObject]@{
                                Name = "@ps-semantic-release/GitHub"
                                Config = [PSCustomObject]@{
                                    assets = @()
                                }
                            }
                        )
                    }
                }
            }

            $github = [GitHub]::new("@ps-semantic-release/GitHub", $context)
            $github.Prepare()

            Should -Invoke Add-WarningLog -Times 1
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
                                Name = "@ps-semantic-release/GitHub"
                                Config = [PSCustomObject]@{
                                    validAssets = @()
                                }
                            }
                        )
                    }
                    Project = [PSCustomObject]@{
                        plugins = @(
                            [PSCustomObject]@{
                                Name = "@ps-semantic-release/GitHub"
                                Config = [PSCustomObject]@{
                                    validAssets = @()
                                }
                            }
                        )
                    }
                }
                NextRelease = [PSCustomObject]@{
                    Version = "2.0.0"
                    Notes = "Release notes"
                    Prerelease = $false
                }
            }

            $github = [GitHub]::new("@ps-semantic-release/GitHub", $context)
            $github.Publish()

            Should -Invoke Add-WarningLog -Times 1
        }
    }
}
