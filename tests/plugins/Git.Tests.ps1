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

Describe "Git" {
    Context "EnsureConfig" {
        It "Should use default config when project config is missing" {
            Mock Add-InformationLog {}
            Mock Add-SuccessLog {}

            $context = [PSCustomObject]@{
                Config = [PSCustomObject]@{
                    Default = [PSCustomObject]@{
                        plugins = @(
                            [PSCustomObject]@{
                                Name = "@ps-semantic-release/Git"
                                Config = [PSCustomObject]@{
                                    message = "chore(release): {NextRelease.Version} [skip ci]`n`n{NextRelease.Notes}"
                                    assets = @()
                                }
                            }
                        )
                    }
                    Project = [PSCustomObject]@{
                        plugins = @(
                            [PSCustomObject]@{
                                Name = "@ps-semantic-release/Git"
                                Config = [PSCustomObject]@{
                                    message = ""
                                    assets = @()
                                }
                            }
                        )
                    }
                }
            }

            # PSUseDeclaredVarsMoreThanAssignments: Variable used to trigger EnsureConfig during construction
            $git = [Git]::new("@ps-semantic-release/Git", $context)
            $git | Should -Not -BeNullOrEmpty
            $context.Config.Project.plugins[0].Config.message | Should -Not -BeNullOrEmpty
        }
    }

    Context "VerifyConditions" {
        BeforeEach {
            Mock Add-InformationLog {}
            Mock Add-SuccessLog {}
        }

        It "Should verify conditions without assets" {
            $context = [PSCustomObject]@{
                Config = [PSCustomObject]@{
                    Default = [PSCustomObject]@{
                        plugins = @(
                            [PSCustomObject]@{
                                Name = "@ps-semantic-release/Git"
                                Config = [PSCustomObject]@{
                                    message = "chore(release): {NextRelease.Version} [skip ci]`n`n{NextRelease.Notes}"
                                    assets = @()
                                }
                            }
                        )
                    }
                    Project = [PSCustomObject]@{
                        plugins = @(
                            [PSCustomObject]@{
                                Name = "@ps-semantic-release/Git"
                                Config = [PSCustomObject]@{
                                    message = "chore(release): {NextRelease.Version} [skip ci]`n`n{NextRelease.Notes}"
                                    assets = @()
                                }
                            }
                        )
                    }
                }
            }

            $git = [Git]::new("@ps-semantic-release/Git", $context)
            { $git.VerifyConditions() } | Should -Not -Throw
        }
    }

    Context "Prepare" {
        BeforeEach {
            Mock Add-InformationLog {}
            Mock Add-SuccessLog {}
            Mock Add-WarningLog {}
            Mock Add-FailureLog {}
        }

        It "Should skip in DryRun mode" {
            $context = [PSCustomObject]@{
                DryRun = $true
                Config = [PSCustomObject]@{
                    Default = [PSCustomObject]@{
                        plugins = @(
                            [PSCustomObject]@{
                                Name = "@ps-semantic-release/Git"
                                Config = [PSCustomObject]@{
                                    message = "chore(release): {NextRelease.Version} [skip ci]`n`n{NextRelease.Notes}"
                                    assets = @()
                                }
                            }
                        )
                    }
                    Project = [PSCustomObject]@{
                        plugins = @(
                            [PSCustomObject]@{
                                Name = "@ps-semantic-release/Git"
                                Config = [PSCustomObject]@{
                                    message = "chore(release): {NextRelease.Version} [skip ci]`n`n{NextRelease.Notes}"
                                    assets = @()
                                }
                            }
                        )
                    }
                }
                NextRelease = [PSCustomObject]@{
                    Version = "2.0.0"
                    Notes = "Release notes"
                }
            }

            $git = [Git]::new("@ps-semantic-release/Git", $context)
            $git.Prepare()

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
                                Name = "@ps-semantic-release/Git"
                                Config = [PSCustomObject]@{
                                    message = "chore(release): {NextRelease.Version} [skip ci]`n`n{NextRelease.Notes}"
                                    assets = @()
                                }
                            }
                        )
                    }
                    Project = [PSCustomObject]@{
                        plugins = @(
                            [PSCustomObject]@{
                                Name = "@ps-semantic-release/Git"
                                Config = [PSCustomObject]@{
                                    message = "chore(release): {NextRelease.Version} [skip ci]`n`n{NextRelease.Notes}"
                                    assets = @()
                                }
                            }
                        )
                    }
                }
                Repository = [PSCustomObject]@{
                    BranchCurrent = "main"
                }
                NextRelease = [PSCustomObject]@{
                    Version = "2.0.0"
                }
            }

            $git = [Git]::new("@ps-semantic-release/Git", $context)
            $git.Publish()

            Should -Invoke Add-WarningLog -Times 1
        }
    }
}
