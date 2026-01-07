function Confirm-GitClean {
    $status = git status --porcelain

    if ($status) {
        throw "Git working tree is not clean. Commit or stash changes before releasing."
    }
}
