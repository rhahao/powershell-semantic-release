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

Describe "Changelog" {
    Context "EnsureConfig" {
        It "Should use default config when project config is missing" {
            Mock Add-InformationLog {}
            Mock Add-SuccessLog {}

            $context = [PSCustomObject]@{
                Config = [PSCustomObject]@{
                    Default = [PSCustomObject]@{
                        plugins = @(
                            [PSCustomObject]@{
                                Name = "@ps-semantic-release/Changelog"
                                Config = [PSCustomObject]@{
                                    file = "CHANGELOG.md"
                                    title = ""
                                }
                            }
                        )
                    }
                    Project = [PSCustomObject]@{
                        plugins = @(
                            [PSCustomObject]@{
                                Name = "@ps-semantic-release/Changelog"
                                Config = [PSCustomObject]@{}
                            }
                        )
                    }
                }
            }

            # PSUseDeclaredVarsMoreThanAssignments: Variable used to trigger EnsureConfig during construction
            $changelog = [Changelog]::new("@ps-semantic-release/Changelog", $context)
            $changelog | Should -Not -BeNullOrEmpty
            $context.Config.Project.plugins[0].Config.file | Should -Not -BeNullOrEmpty
        }
    }

    Context "VerifyConditions" {
        BeforeEach {
            Mock Add-InformationLog {}
            Mock Add-SuccessLog {}
        }

        It "Should validate markdown file extension" {
            $context = [PSCustomObject]@{
                Config = [PSCustomObject]@{
                    Default = [PSCustomObject]@{
                        plugins = @(
                            [PSCustomObject]@{
                                Name = "@ps-semantic-release/Changelog"
                                Config = [PSCustomObject]@{
                                    file = "CHANGELOG.md"
                                    title = ""
                                }
                            }
                        )
                    }
                    Project = [PSCustomObject]@{
                        plugins = @(
                            [PSCustomObject]@{
                                Name = "@ps-semantic-release/Changelog"
                                Config = [PSCustomObject]@{
                                    file = "CHANGELOG.md"
                                    title = ""
                                }
                            }
                        )
                    }
                }
            }

            $changelog = [Changelog]::new("@ps-semantic-release/Changelog", $context)
            { $changelog.VerifyConditions() } | Should -Not -Throw
        }

        It "Should throw error for non-markdown file" {
            $context = [PSCustomObject]@{
                Config = [PSCustomObject]@{
                    Default = [PSCustomObject]@{
                        plugins = @(
                            [PSCustomObject]@{
                                Name = "@ps-semantic-release/Changelog"
                                Config = [PSCustomObject]@{
                                    file = "CHANGELOG.txt"
                                    title = ""
                                }
                            }
                        )
                    }
                    Project = [PSCustomObject]@{
                        plugins = @(
                            [PSCustomObject]@{
                                Name = "@ps-semantic-release/Changelog"
                                Config = [PSCustomObject]@{
                                    file = "CHANGELOG.txt"
                                    title = ""
                                }
                            }
                        )
                    }
                }
            }

            $changelog = [Changelog]::new("@ps-semantic-release/Changelog", $context)
            { $changelog.VerifyConditions() } | Should -Throw
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
                                Name = "@ps-semantic-release/Changelog"
                                Config = [PSCustomObject]@{
                                    file = "CHANGELOG.md"
                                    title = ""
                                }
                            }
                        )
                    }
                    Project = [PSCustomObject]@{
                        plugins = @(
                            [PSCustomObject]@{
                                Name = "@ps-semantic-release/Changelog"
                                Config = [PSCustomObject]@{
                                    file = "CHANGELOG.md"
                                    title = ""
                                }
                            }
                        )
                    }
                }
                NextRelease = [PSCustomObject]@{
                    Notes = "## 2.0.0 (2024-01-01)`n`n### Features`n* **api:** new feature"
                }
            }

            $changelog = [Changelog]::new("@ps-semantic-release/Changelog", $context)
            $changelog.Prepare()

            Should -Invoke Add-WarningLog -Times 1
        }
    }
}
