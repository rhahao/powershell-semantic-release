## [1.8.0](https://github.com/rhahao/powershell-semantic-release/compare/v1.7.1...v1.8.0) (2026-01-10)

### Bug Fixes

* **plugins:** call EnsureConfig on plugin load ([d8673b5](https://github.com/rhahao/powershell-semantic-release/commit/d8673b56e890fa5be8b2eb519635d3202ddb562e))
* **plugins:** move release notes formatter for DryRun ([461ca21](https://github.com/rhahao/powershell-semantic-release/commit/461ca21b8dc93cde31104cf6d205744fa23938b1))

### Features

* **module:** rewrite plugins steps call ([bf3d278](https://github.com/rhahao/powershell-semantic-release/commit/bf3d2780ccbd2d3a502aa956bb2c397077c7e602))
* **plugins:** set condition for DryRun in Exec ([a355a5c](https://github.com/rhahao/powershell-semantic-release/commit/a355a5c58af2fbf6ec52700006c49cea713b128f))
* **plugins:** update log prefix ([f905826](https://github.com/rhahao/powershell-semantic-release/commit/f905826d21e57a23a218cb8faedbcd23a2660154))

## [1.7.1](https://github.com/rhahao/powershell-semantic-release/compare/v1.7.0...v1.7.1) (2026-01-09)

### Bug Fixes

* **plugins:** add missing logging for Exec ([2a6cc34](https://github.com/rhahao/powershell-semantic-release/commit/2a6cc3483df6171c19a9ba48a12d74292f526bb5))

## [1.7.0](https://github.com/rhahao/powershell-semantic-release/compare/v1.6.0...v1.7.0) (2026-01-09)

### Bug Fixes

* **scripts:** use channel for params in create-dist.ps1 ([15bc93c](https://github.com/rhahao/powershell-semantic-release/commit/15bc93c8b4c48f8041c7a66bf76e6c7e9670c237))

### Features

* **plugins:** add Publish step for Git ([1bfdffd](https://github.com/rhahao/powershell-semantic-release/commit/1bfdffd6a7cfcaa15eab03fd8697d75a238f87d3))

## [1.6.0](https://github.com/rhahao/powershell-semantic-release/compare/v1.5.0...v1.6.0) (2026-01-09)

### Bug Fixes

* **helpers:** update commits sorting ([d23b6f9](https://github.com/rhahao/powershell-semantic-release/commit/d23b6f9eef9b4e9cca0e2da82758b9e3f3f0f58c))
* **module:** allow DryRun mode without CI_TOKEN ([bc3d8b6](https://github.com/rhahao/powershell-semantic-release/commit/bc3d8b6551097bc5905cc64337c0fcf7a4be6135))
* **module:** include missing VerifyConditions step ([85ea4a0](https://github.com/rhahao/powershell-semantic-release/commit/85ea4a0bd9860182701d6a66e13c9d666db03eef))
* **module:** update exit code for Invoke-SemanticRelease ([51a5af7](https://github.com/rhahao/powershell-semantic-release/commit/51a5af7842b3eece00b6ab9c14d8925c3815f7dc))
* **plugins:** ReleaseNotesGenerator failed to capture DryRun value ([25bd5cd](https://github.com/rhahao/powershell-semantic-release/commit/25bd5cd8c2e5efc5afc22579535d157fe75be7a7))
* **plugins:** string with double quotes not showing properly ([e5ae22b](https://github.com/rhahao/powershell-semantic-release/commit/e5ae22baf827c64af9cf6d008da8914777cc2327))

### Features

* **helpers:** restructure release context ([b0de024](https://github.com/rhahao/powershell-semantic-release/commit/b0de024d2c58a3a891059d1612e375e66552d3e1))
* **module:** add placeholder for Publish step ([db1791f](https://github.com/rhahao/powershell-semantic-release/commit/db1791ff0180fccc335b6e0c38127485bcb454e3))
* **module:** migrate release notes generator to plugin ([9d1a5e1](https://github.com/rhahao/powershell-semantic-release/commit/9d1a5e12516837fa0557d6b40c446e1558f86786))
* **module:** migrate writing changelog to plugin ([d40d01c](https://github.com/rhahao/powershell-semantic-release/commit/d40d01ce71d41c18370bbe94493ec3075cebdfd6))
* **module:** restructure module for plugins extensions ([9949d49](https://github.com/rhahao/powershell-semantic-release/commit/9949d49604cf5c9d570dc508349b19b429b72a08))
* **module:** support commits sorting ([22100af](https://github.com/rhahao/powershell-semantic-release/commit/22100af42425828b32945356ecc57c9de5255afb))
* **module:** use New-GitTag function ([a2a2172](https://github.com/rhahao/powershell-semantic-release/commit/a2a2172b6188e30f0027c0acbd5599e9b16fad16))
* **plugins:** add Exec plugin ([f4d93b7](https://github.com/rhahao/powershell-semantic-release/commit/f4d93b769c59dbed228463d936f0738776c02e78))
* **plugins:** add GitHub plugin ([1105bdf](https://github.com/rhahao/powershell-semantic-release/commit/1105bdfd506d9f10478704d3051be3c03ba6e354))
* **plugins:** add Prepare step for Git ([8acd240](https://github.com/rhahao/powershell-semantic-release/commit/8acd2402bb9eb99065362499c7c951ec3a040c4c))
* **plugins:** add Publish step for GitHub ([d6731b9](https://github.com/rhahao/powershell-semantic-release/commit/d6731b983db1e7cf0324691632399b09198e995b))
* **plugins:** update GitHub and GitLab plugins ([f39a412](https://github.com/rhahao/powershell-semantic-release/commit/f39a4125c71f60892e8e62c65060f6d99a1daed7))
* **plugins:** update ReleaseNotesGenerator to sort commit section ([e5555bd](https://github.com/rhahao/powershell-semantic-release/commit/e5555bd8efc610056ac2c5ee1a3fb45ac584a7de))
* **plugins:** update VerifyConditions step for Git ([2cca98f](https://github.com/rhahao/powershell-semantic-release/commit/2cca98f87ee845215541e1f5f1c2ce7e653c17c3))

## [1.5.0](https://github.com/rhahao/powershell-semantic-release/compare/v1.4.1...v1.5.0) (2026-01-08)

### Features

* **Push-GitAssets:** show number of files to commit ([3498596](https://github.com/rhahao/powershell-semantic-release/commit/349859624ac7d84cbcf922607ddb27c3b401a5e7))

## [1.4.1](https://github.com/rhahao/powershell-semantic-release/compare/v1.4.0...v1.4.1) (2026-01-08)

### Bug Fixes

* **private:** suppress output from Invoke-RestMethod in ci releases ([d5a9702](https://github.com/rhahao/powershell-semantic-release/commit/d5a97020d0b62891aa1ac4f4f432edff4c0065a8))
* **New-ReleaseNotes:** update title styling for minor update ([a6e3683](https://github.com/rhahao/powershell-semantic-release/commit/a6e3683df8fc1be85344ebcf25c2ec7b70b6a820))

## [1.4.0](https://github.com/rhahao/powershell-semantic-release/compare/v1.3.1...v1.4.0) (2026-01-08)

### Features

* **helpers:** update releaser bot account name ([408e669](https://github.com/rhahao/powershell-semantic-release/commit/408e669db7f26a1f760f8a56c9667db3835b852e))
* **module:** add Publish-Release functions ([0d2ad8f](https://github.com/rhahao/powershell-semantic-release/commit/0d2ad8f49b28a0e68f54eb77486e2aa2646b83e3))
* **Invoke-ReleaseScript:** log the script value ([61bdf58](https://github.com/rhahao/powershell-semantic-release/commit/61bdf5897e63c20f99fc0add9858f7cceead3b2d))

## [1.3.1](https://github.com/rhahao/powershell-semantic-release/compare/v1.3.0...v1.3.1) (2026-01-08)

### Bug Fixes

* **scripts:** add missing New-ModuleManifest command ([f1688c7](https://github.com/rhahao/powershell-semantic-release/commit/f1688c7ff253e91376d7703c52a125c1153482ed))
* **Set-GitIdentity:** suppress git config change log ([59dafc9](https://github.com/rhahao/powershell-semantic-release/commit/59dafc905b0a788a6ee636584b6725f57f9ab985))
* **Invoke-SemanticRelease:** keep git config during DryRun ([7fd4e04](https://github.com/rhahao/powershell-semantic-release/commit/7fd4e04b59c5d4e34ad3715cd8bca72db0e0fd66))

## [1.3.0](https://github.com/rhahao/powershell-semantic-release/compare/v1.2.0...v1.3.0) (2026-01-08)

### Features

* **helpers:** add Set-GitIdentity function ([a79a61d](https://github.com/rhahao/powershell-semantic-release/commit/a79a61d8bf335e4b1577716c782ff9fa3715362b))

