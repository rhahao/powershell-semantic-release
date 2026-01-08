function New-GitTag {
    param ($version)

    try {
        $tag = "v$Version"

        if (Test-GitTagExists $tag) {
            throw "tag $tag already exists"
        }

        if ($Context.DryRun) {
            Add-ConsoleLog "skip $tag tag creation in DryRun mode"
            return
        }

        git tag $tag 2>$null
        git push origin $tag --quiet
    }
    catch {
        throw $_
    }    
}
