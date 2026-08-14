BeforeAll {
    $modulePath = Join-Path $PSScriptRoot "../PSSemanticRelease"
    Import-Module $modulePath -Force

    # Dot-source private scripts to access internal functions for testing
    Get-ChildItem "$modulePath/private/*.ps1" | ForEach-Object { . $_ }
}

AfterAll {
    Remove-Module PSSemanticRelease -Force -ErrorAction SilentlyContinue
}

Describe "New-ReleaseContext" {
    Context "When creating context with DryRun" {
        BeforeEach {
            Mock Get-SemanticReleaseConfig {
                return [PSCustomObject]@{
                    Default = [PSCustomObject]@{
                        branches = @("main")
                    }
                    Config = [PSCustomObject]@{
                        branches = @("main")
                    }
                }
            }
            Mock Get-GitRemoteUrl { return "https://github.com/user/repo.git" }
            Mock Resolve-RepositoryUrl { return "https://github.com/user/repo" }
            Mock Get-CIContext {
                return [PSCustomObject]@{
                    IsCI = $false
                    isPr = $false
                    Branch = $null
                    Token = $null
                }
            }
        }

        It "Should create context with DryRun enabled" {
            $context = New-ReleaseContext $true
            $context.DryRun | Should -Be $true
        }

        It "Should create context with DryRun disabled" {
            $context = New-ReleaseContext $false
            $context.DryRun | Should -Be $false
        }
    }

    Context "When in CI environment" {
        BeforeEach {
            Mock Get-SemanticReleaseConfig {
                return [PSCustomObject]@{
                    Default = [PSCustomObject]@{
                        branches = @("main")
                    }
                    Config = [PSCustomObject]@{
                        branches = @("main")
                    }
                }
            }
            Mock Get-GitRemoteUrl { return "https://github.com/user/repo.git" }
            Mock Resolve-RepositoryUrl { return "https://github.com/user/repo" }
            Mock Get-CIContext {
                return [PSCustomObject]@{
                    IsCI = $true
                    isPr = $false
                    Branch = "main"
                    Token = "test-token"
                }
            }
        }

        It "Should include CI context in the context object" {
            $context = New-ReleaseContext
            $context.EnvCI.IsCI | Should -Be $true
            $context.EnvCI.Branch | Should -Be "main"
            $context.EnvCI.Token | Should -Be "test-token"
        }
    }
}
