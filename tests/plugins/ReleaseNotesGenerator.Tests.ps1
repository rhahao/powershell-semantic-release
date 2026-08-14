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

Describe "ReleaseNotesGenerator" {
    Context "GenerateNotes" {
        BeforeEach {
            Mock Add-InformationLog {}
            Mock Add-SuccessLog {}
            Mock Get-CompareUrl { return "https://github.com/test/repo/compare/v1.0.0...v2.0.0" }
            Mock Get-CommitUrl { return "https://github.com/test/repo/commit/abc123def456" }
            Mock Format-SortCommits { param($Commits); return $Commits }
        }

        It "Should generate release notes with commits" {
            $context = [PSCustomObject]@{
                Config = [PSCustomObject]@{
                    Default = [PSCustomObject]@{
                        plugins = @(
                            [PSCustomObject]@{
                                Name = "@ps-semantic-release/CommitAnalyzer"
                                Config = [PSCustomObject]@{
                                    releaseRules = @(
                                        [PSCustomObject]@{ type = "feat"; release = "minor"; section = "Features" }
                                        [PSCustomObject]@{ type = "fix"; release = "patch"; section = "Bug Fixes" }
                                    )
                                }
                            },
                            [PSCustomObject]@{
                                Name = "@ps-semantic-release/ReleaseNotesGenerator"
                                Config = [PSCustomObject]@{
                                    commitsSort = @("scope", "subject")
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
                                        [PSCustomObject]@{ type = "fix"; release = "patch"; section = "Bug Fixes" }
                                    )
                                }
                            },
                            [PSCustomObject]@{
                                Name = "@ps-semantic-release/ReleaseNotesGenerator"
                                Config = [PSCustomObject]@{
                                    commitsSort = @("scope", "subject")
                                }
                            }
                        )
                    }
                }
                Repository = [PSCustomObject]@{
                    Url = "https://github.com/test/repo"
                }
                CurrentVersion = [PSCustomObject]@{
                    Branch = "1.0.0"
                }
                NextRelease = [PSCustomObject]@{
                    Version = "2.0.0"
                    Type = "minor"
                }
                Commits = [PSCustomObject]@{
                    List = @(
                        [PSCustomObject]@{
                            Type = "feat"
                            Message = "feat(api): add new feature"
                            Subject = "add new feature"
                            Scope = "api"
                            Breaking = $false
                            Sha = "abc123def456"
                        }
                    )
                    Formatted = "1 commit"
                }
            }

            $generator = [ReleaseNotesGenerator]::new("@ps-semantic-release/ReleaseNotesGenerator", $context)
            $notes = $generator.GenerateNotes()
            $notes | Should -Not -BeNullOrEmpty
            $notes | Should -Match "2.0.0"
            $notes | Should -Match "Features"
        }

        It "Should handle empty commits list" {
            $context = [PSCustomObject]@{
                Config = [PSCustomObject]@{
                    Default = [PSCustomObject]@{
                        plugins = @(
                            [PSCustomObject]@{
                                Name = "@ps-semantic-release/CommitAnalyzer"
                                Config = [PSCustomObject]@{
                                    releaseRules = @()
                                }
                            },
                            [PSCustomObject]@{
                                Name = "@ps-semantic-release/ReleaseNotesGenerator"
                                Config = [PSCustomObject]@{
                                    commitsSort = @("scope", "subject")
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
                            },
                            [PSCustomObject]@{
                                Name = "@ps-semantic-release/ReleaseNotesGenerator"
                                Config = [PSCustomObject]@{
                                    commitsSort = @("scope", "subject")
                                }
                            }
                        )
                    }
                }
                Repository = [PSCustomObject]@{
                    Url = "https://github.com/test/repo"
                }
                CurrentVersion = [PSCustomObject]@{
                    Branch = "1.0.0"
                }
                NextRelease = [PSCustomObject]@{
                    Version = "2.0.0"
                    Type = "minor"
                }
                Commits = [PSCustomObject]@{
                    List = @()
                    Formatted = "0 commits"
                }
            }

            $generator = [ReleaseNotesGenerator]::new("@ps-semantic-release/ReleaseNotesGenerator", $context)
            $notes = $generator.GenerateNotes()
            $notes | Should -Be ""
        }
    }
}
