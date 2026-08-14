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

Describe "CommitAnalyzer" {
    Context "EnsureConfig" {
        It "Should use default config when project config is missing" {
            Mock Add-InformationLog {}
            Mock Add-SuccessLog {}

            $context = [PSCustomObject]@{
                Config = [PSCustomObject]@{
                    Default = [PSCustomObject]@{
                        plugins = @(
                            [PSCustomObject]@{
                                Name = "@ps-semantic-release/CommitAnalyzer"
                                Config = [PSCustomObject]@{
                                    releaseRules = @(
                                        [PSCustomObject]@{ type = "fix"; release = "patch"; section = "Bug Fixes" }
                                    )
                                }
                            }
                        )
                    }
                    Project = [PSCustomObject]@{
                        plugins = @(
                            [PSCustomObject]@{
                                Name = "@ps-semantic-release/CommitAnalyzer"
                                Config = [PSCustomObject]@{
                                    releaseRules = @()
                                }
                            }
                        )
                    }
                }
            }

            # PSUseDeclaredVarsMoreThanAssignments: Variable used to trigger EnsureConfig during construction
            $analyzer = [CommitAnalyzer]::new("@ps-semantic-release/CommitAnalyzer", $context)
            $analyzer | Should -Not -BeNullOrEmpty
            $context.Config.Project.plugins[0].Config.releaseRules.Count | Should -BeGreaterThan 0
        }
    }

    Context "AnalyzeCommits" {
        BeforeEach {
            Mock Add-InformationLog {}
            Mock Add-SuccessLog {}
            Mock Get-ReleaseTypeFromLists { return "minor" }
        }

        It "Should analyze fix commits as patch" {
            Mock Get-ReleaseTypeFromLists { return "patch" }

            $context = [PSCustomObject]@{
                Config = [PSCustomObject]@{
                    Default = [PSCustomObject]@{
                        plugins = @(
                            [PSCustomObject]@{
                                Name = "@ps-semantic-release/CommitAnalyzer"
                                Config = [PSCustomObject]@{
                                    releaseRules = @(
                                        [PSCustomObject]@{ type = "fix"; release = "patch"; section = "Bug Fixes" }
                                    )
                                }
                            }
                        )
                    }
                    Project = [PSCustomObject]@{
                        plugins = @(
                            [PSCustomObject]@{
                                Name = "@ps-semantic-release/CommitAnalyzer"
                                Config = [PSCustomObject]@{
                                    releaseRules = @(
                                        [PSCustomObject]@{ type = "fix"; release = "patch"; section = "Bug Fixes" }
                                    )
                                }
                            }
                        )
                    }
                }
                Commits = [PSCustomObject]@{
                    List = @(
                        [PSCustomObject]@{
                            Type = "fix"
                            Message = "fix: fix bug"
                            Subject = "fix bug"
                            Scope = "api"
                            Breaking = $false
                            Sha = "abc123"
                        }
                    )
                    Formatted = "1 commit"
                }
            }

            $analyzer = [CommitAnalyzer]::new("@ps-semantic-release/CommitAnalyzer", $context)
            $result = $analyzer.AnalyzeCommits()
            $result | Should -Be "patch"
        }

        It "Should analyze feat commits as minor" {
            Mock Get-ReleaseTypeFromLists { return "minor" }

            $context = [PSCustomObject]@{
                Config = [PSCustomObject]@{
                    Default = [PSCustomObject]@{
                        plugins = @(
                            [PSCustomObject]@{
                                Name = "@ps-semantic-release/CommitAnalyzer"
                                Config = [PSCustomObject]@{
                                    releaseRules = @(
                                        [PSCustomObject]@{ type = "feat"; release = "minor"; section = "Features" }
                                    )
                                }
                            }
                        )
                    }
                    Project = [PSCustomObject]@{
                        plugins = @(
                            [PSCustomObject]@{
                                Name = "@ps-semantic-release/CommitAnalyzer"
                                Config = [PSCustomObject]@{
                                    releaseRules = @(
                                        [PSCustomObject]@{ type = "feat"; release = "minor"; section = "Features" }
                                    )
                                }
                            }
                        )
                    }
                }
                Commits = [PSCustomObject]@{
                    List = @(
                        [PSCustomObject]@{
                            Type = "feat"
                            Message = "feat: add new feature"
                            Subject = "add new feature"
                            Scope = "api"
                            Breaking = $false
                            Sha = "abc123"
                        }
                    )
                    Formatted = "1 commit"
                }
            }

            $analyzer = [CommitAnalyzer]::new("@ps-semantic-release/CommitAnalyzer", $context)
            $result = $analyzer.AnalyzeCommits()
            $result | Should -Be "minor"
        }

        It "Should analyze breaking commits as major" {
            Mock Get-ReleaseTypeFromLists { return "major" }

            $context = [PSCustomObject]@{
                Config = [PSCustomObject]@{
                    Default = [PSCustomObject]@{
                        plugins = @(
                            [PSCustomObject]@{
                                Name = "@ps-semantic-release/CommitAnalyzer"
                                Config = [PSCustomObject]@{
                                    releaseRules = @(
                                        [PSCustomObject]@{ type = "feat"; release = "minor"; section = "Features" }
                                    )
                                }
                            }
                        )
                    }
                    Project = [PSCustomObject]@{
                        plugins = @(
                            [PSCustomObject]@{
                                Name = "@ps-semantic-release/CommitAnalyzer"
                                Config = [PSCustomObject]@{
                                    releaseRules = @(
                                        [PSCustomObject]@{ type = "feat"; release = "minor"; section = "Features" }
                                    )
                                }
                            }
                        )
                    }
                }
                Commits = [PSCustomObject]@{
                    List = @(
                        [PSCustomObject]@{
                            Type = "feat"
                            Message = "feat!: breaking change"
                            Subject = "breaking change"
                            Scope = "api"
                            Breaking = $true
                            Sha = "abc123"
                        }
                    )
                    Formatted = "1 commit"
                }
            }

            $analyzer = [CommitAnalyzer]::new("@ps-semantic-release/CommitAnalyzer", $context)
            $result = $analyzer.AnalyzeCommits()
            $result | Should -Be "major"
        }
    }
}
