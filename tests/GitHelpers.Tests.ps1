BeforeAll {
    $modulePath = Join-Path $PSScriptRoot "../PSSemanticRelease"
    Import-Module $modulePath -Force

    # Dot-source private scripts to access internal functions for testing
    Get-ChildItem "$modulePath/private/*.ps1" | ForEach-Object { . $_ }
}

AfterAll {
    Remove-Module PSSemanticRelease -Force -ErrorAction SilentlyContinue
}

Describe "Get-CommitUrl" {
    Context "GitHub repository" {
        It "Should return GitHub commit URL" {
            $result = Get-CommitUrl -RepositoryUrl "https://github.com/user/repo" -Sha "abc123"
            $result | Should -Be "https://github.com/user/repo/commit/abc123"
        }
    }

    Context "GitLab repository" {
        It "Should return GitLab commit URL" {
            $result = Get-CommitUrl -RepositoryUrl "https://gitlab.com/user/repo" -Sha "abc123"
            $result | Should -Be "https://gitlab.com/user/repo/-/commit/abc123"
        }
    }

    Context "Unknown repository" {
        It "Should return null for unknown repository" {
            $result = Get-CommitUrl -RepositoryUrl "https://example.com/user/repo" -Sha "abc123"
            $result | Should -BeNullOrEmpty
        }
    }
}

Describe "Get-CompareUrl" {
    Context "GitHub repository" {
        It "Should return GitHub compare URL" {
            $result = Get-CompareUrl -RepositoryUrl "https://github.com/user/repo" -FromVersion "1.0.0" -ToVersion "2.0.0"
            $result | Should -Be "https://github.com/user/repo/compare/v1.0.0...v2.0.0"
        }
    }

    Context "GitLab repository" {
        It "Should return GitLab compare URL" {
            $result = Get-CompareUrl -RepositoryUrl "https://gitlab.com/user/repo" -FromVersion "1.0.0" -ToVersion "2.0.0"
            $result | Should -Be "https://gitlab.com/user/repo/-/compare/v1.0.0...v2.0.0"
        }
    }

    Context "Null repository URL" {
        It "Should return null when repository URL is null" {
            $result = Get-CompareUrl -RepositoryUrl $null -FromVersion "1.0.0" -ToVersion "2.0.0"
            $result | Should -BeNullOrEmpty
        }
    }
}

Describe "Get-BumpedSemanticVersion" {
    Context "Version bumping logic" {
        It "Should handle major version bump correctly" {
            $result = Get-BumpedSemanticVersion -Version "1.2.3" -Type "major"
            $result | Should -Be "2.0.0"
        }

        It "Should handle minor version bump correctly" {
            $result = Get-BumpedSemanticVersion -Version "1.2.3" -Type "minor"
            $result | Should -Be "1.3.0"
        }

        It "Should handle patch version bump correctly" {
            $result = Get-BumpedSemanticVersion -Version "1.2.3" -Type "patch"
            $result | Should -Be "1.2.4"
        }

        It "Should handle version with leading zeros" {
            $result = Get-BumpedSemanticVersion -Version "1.0.0" -Type "patch"
            $result | Should -Be "1.0.1"
        }
    }
}
