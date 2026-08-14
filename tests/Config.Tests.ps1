BeforeAll {
    $modulePath = Join-Path $PSScriptRoot "../PSSemanticRelease"
    Import-Module $modulePath -Force

    # Dot-source private scripts to access internal functions for testing
    Get-ChildItem "$modulePath/private/*.ps1" | ForEach-Object { . $_ }
}

AfterAll {
    Remove-Module PSSemanticRelease -Force -ErrorAction SilentlyContinue
}



Describe "Confirm-ReleaseBranch" {
    Context "When current branch is a release branch" {
        It "Should return true for main branch" {
            $context = [PSCustomObject]@{
                Config = [PSCustomObject]@{
                    Default = [PSCustomObject]@{
                        branches = @("main", "master")
                    }
                    Project = [PSCustomObject]@{
                        branches = $null
                    }
                }
                Repository = [PSCustomObject]@{
                    BranchCurrent = "main"
                }
                NextRelease = [PSCustomObject]@{
                    Channel = $null
                    Prerelease = $false
                }
            }

            $result = Confirm-ReleaseBranch -context $context
            $result | Should -Be $true
            $context.NextRelease.Channel | Should -Be "default"
            $context.NextRelease.Prerelease | Should -Be $false
        }

        It "Should return true for master branch" {
            $context = [PSCustomObject]@{
                Config = [PSCustomObject]@{
                    Default = [PSCustomObject]@{
                        branches = @("main", "master")
                    }
                    Project = [PSCustomObject]@{
                        branches = $null
                    }
                }
                Repository = [PSCustomObject]@{
                    BranchCurrent = "master"
                }
                NextRelease = [PSCustomObject]@{
                    Channel = $null
                    Prerelease = $false
                }
            }

            $result = Confirm-ReleaseBranch -context $context
            $result | Should -Be $true
        }

        It "Should return true for prerelease branch" {
            $context = [PSCustomObject]@{
                Config = [PSCustomObject]@{
                    Default = [PSCustomObject]@{
                        branches = @(
                            "main",
                            @{ name = "beta"; prerelease = "beta" },
                            @{ name = "alpha"; prerelease = "alpha" }
                        )
                    }
                    Project = [PSCustomObject]@{
                        branches = $null
                    }
                }
                Repository = [PSCustomObject]@{
                    BranchCurrent = "beta"
                }
                NextRelease = [PSCustomObject]@{
                    Channel = $null
                    Prerelease = $false
                }
            }

            $result = Confirm-ReleaseBranch -context $context
            $result | Should -Be $true
            $context.NextRelease.Channel | Should -Be "beta"
            $context.NextRelease.Prerelease | Should -Be $true
        }
    }

    Context "When current branch is not a release branch" {
        It "Should return false for feature branch" {
            $context = [PSCustomObject]@{
                Config = [PSCustomObject]@{
                    Default = [PSCustomObject]@{
                        branches = @("main", "master")
                    }
                    Project = [PSCustomObject]@{
                        branches = $null
                    }
                }
                Repository = [PSCustomObject]@{
                    BranchCurrent = "feature/new-feature"
                }
                NextRelease = [PSCustomObject]@{
                    Channel = $null
                    Prerelease = $false
                }
            }

            $result = Confirm-ReleaseBranch -context $context
            $result | Should -Be $false
        }
    }

    Context "When project has custom branch configuration" {
        It "Should use project branches over default" {
            $context = [PSCustomObject]@{
                Config = [PSCustomObject]@{
                    Default = [PSCustomObject]@{
                        branches = @("main", "master")
                    }
                    Project = [PSCustomObject]@{
                        branches = @("production", "develop")
                    }
                }
                Repository = [PSCustomObject]@{
                    BranchCurrent = "production"
                }
                NextRelease = [PSCustomObject]@{
                    Channel = $null
                    Prerelease = $false
                }
            }

            $result = Confirm-ReleaseBranch -context $context
            $result | Should -Be $true
        }
    }
}
