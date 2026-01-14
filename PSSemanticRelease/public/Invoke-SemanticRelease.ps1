$ErrorActionPreference = "Stop"

function Invoke-SemanticRelease {
    param([switch]$DryRun)

    Get-EnvFromFile

    $semanticVersion = Get-PSSemanticReleaseVersion
    Add-InformationLog "PSSemanticRelease version $semanticVersion"

    Test-GitRepository

    $context = New-ReleaseContext $DryRun
    $currentBranch = $context.EnvCI.Branch

    if (-not $currentBranch) {
        $currentBranch = Get-GitBranchCurrent
    }

    $context.Repository.BranchCurrent = $currentBranch

    if (-not $context.EnvCI.IsCI -and -not $context.DryRun -and -not $context.noCi) {
        Add-WarningLog "This run was not triggered in a known CI environment, running in DryRun mode."
        $context.DryRun = $true;
    }

    if ($context.EnvCI.IsCI -and $context.EnvCi.isPr -and -not $context.noCi) {
        Add-InformationLog "This run was triggered by a pull request and therefore a new version will not be published."
        return false;
    }

    Update-ConfigPluginsList -context $context

    $allPlugins = Get-SemanticReleasePlugins -context $context

    $plugins = [Plugins]::new($allPlugins)

    # List all loaded plugins and steps
    $plugins.List()

    $isReleaseBranch = Confirm-ReleaseBranch -context $context

    if (-not $isReleaseBranch) {            
        $releaseBranches = (Format-ReleaseBranchesList $context.Config.Project.branches) -join ", "

        return Add-InformationLog "This run was triggered on the branch ${currentBranch}, while PSSemanticRelease is configured to only publish from $releaseBranches, therefore a new version will not be published."
    }

    if (-not $currentBranch) {
        return Add-InformationLog "Unable to determine the current branch, therefore a new version will not be published."
    }

    $logRan = "Running automated release from branch $currentBranch on repository $($context.Repository.RemoteUrl)"

    if ($context.DryRun) {
        $logRan += " in DryRun mode"
        Add-WarningLog $logRan
    }
    else {
        Add-SuccessLog $logRan
    }

    try {
        Test-GitPushAccess -context $context
    }
    catch {
        throw $_
    }

    Add-SuccessLog "Allowed to push to the Git repository"

    $plugins.VerifyConditions()

    $unifyTag = $context.Config.Project.unifyTag
    $currentVersion = Get-CurrentSemanticVersion $unifyTag
    $context.CurrentVersion.Branch = $currentVersion

    if (-not $currentVersion) {
        if ($unifyTag) {
            Add-InformationLog "No git tag version found, retrieving all commits"
        }
        else {
            Add-InformationLog "No git tag version found on branch $currentBranch, retrieving all commits"
        }
    }
    else {
        if ($unifyTag) {
            Add-InformationLog "Found git tag v$currentVersion"            
        }
        else {
            Add-InformationLog "Found git tag v$currentVersion on branch $currentBranch"
        }
            
    }

    $commitsList = Get-ConventionalCommits
    $context.Commits.List = $commitsList
    $context.Commits.Formatted = if ($commitsList.Count -eq 1) { "1 commit" } else { "$($commitsList.Count) commits" }

    if ($commitsList.Count -eq 0) {
        return Add-InformationLog "No commits found, no release needed"
    }
    else {
        Add-InformationLog -Message "Found $($context.Commits.Formatted) on branch $currentBranch since last release"
    }

    $releaseType = $plugins.AnalyzeCommits()

    if (-not $releaseType) {
        return Add-InformationLog "There are no relevant changes, so no new version is released."
    }

    $context.NextRelease.Type = $releaseType

    $nextVersion = Get-NextSemanticVersion -context $context

    $context.NextRelease.Version = $nextVersion
    $channel = $context.NextRelease.Channel
            
    $versionChannel = if ($channel -ne "default") { "$($channel) " }
    
    if ($null -eq $currentBranch) {
        Add-InformationLog "There is no previous $($versionChannel)release, the next release version is $nextVersion"
    }
    else {
        Add-InformationLog "The next $($versionChannel)release version is $nextVersion"
    }

    $plugins.VerifyRelease()

    $context.NextRelease.Notes = $plugins.GenerateNotes()

    $plugins.Prepare()

    if ($context.DryRun) {
        Add-WarningLog "Skip v$nextVersion tag creation in DryRun mode"
    }
    else {
        New-GitTag -context $context
        Push-GitTag "v$nextVersion"

        Add-SuccessLog "Created tag v$nextVersion"
    }

    $plugins.Publish()

    Add-SuccessLog "Published release $nextVersion on $channel channel"

    # SHOW RELEASE NOTES FOR DRY RUN
    if ($context.DryRun) {    
        $versionNext = $context.NextRelease.Version        
        $notes = Format-ReleaseNotesDryRun $context.NextRelease.Notes
        Add-InformationLog "Release note for version ${versionNext}:`n$notes"
    }
}
