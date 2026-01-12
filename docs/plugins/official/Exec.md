# @ps-semantic-release/Exec

A plugin that runs user-provided PowerShell scripts at various lifecycle steps. It supports custom scripts for verification, commit analysis, release verification, release notes generation, preparation, and publishing. Scripts can receive expanded context placeholders as arguments and are executed in a separate PowerShell process.

---

## Configuration

- `verifyConditionsPsScript`:

  - Type: string
  - Required: no
  - Default: none
  - Description: Command line string pointing to a `.ps1` script and optional arguments to run during `VerifyConditions`.

- `analyzeCommitsPsScript`:

  - Type: string
  - Required: no
  - Default: none
  - Description: Command line string for a script to run during `AnalyzeCommits`.

- `verifyReleasePsScript`:

  - Type: string
  - Required: no
  - Default: none
  - Description: Command line string for a script to run during `VerifyRelease`.

- `generateNotesPsScript`:

  - Type: string
  - Required: no
  - Default: none
  - Description: Command line string for a script to run during `GenerateNotes`.

- `preparePsScript`:

  - Type: string
  - Required: no
  - Default: none
  - Description: Command line string for a script to run during `Prepare`.

- `publishPsScript`:
  - Type: string
  - Required: no
  - Default: none
  - Description: Command line string for a script to run during `Publish`. When configured, the plugin will skip this script in DryRun mode unless the script is intended to run in DryRun (the plugin halts execution of publish scripts when `Context.DryRun` is true).

**Example config snippet**

```json
{
  "plugins": [
    [
      "@ps-semantic-release/Exec",
      {
        "preparePsScript": "scripts/prepare-release.ps1 {NextRelease.Version}",
        "publishPsScript": "scripts/publish-release.ps1 {NextRelease.Version} {NextRelease.Channel}"
      }
    ]
  ]
}
```

---

## Behavior details

### `VerifyConditions`

- If `verifyConditionsPsScript` is configured, the plugin calls `RunScript("VerifyConditions", $false, <script>)`.
- The script is executed even in DryRun mode unless the `haltDryRun` flag is set for that step.

### `AnalyzeCommits`

- If `analyzeCommitsPsScript` is configured, the plugin calls `RunScript("AnalyzeCommits", $false, <script>)`.
- Useful for custom commit analysis or to augment built-in analyzers.

### `VerifyRelease`

- If `verifyReleasePsScript` is configured, the plugin calls `RunScript("VerifyRelease", $false, <script>)`.
- Intended for final checks before notes generation or publishing.

### `GenerateNotes`

- If `generateNotesPsScript` is configured, the plugin calls `RunScript("GenerateNotes", $false, <script>)`.
- Allows custom release notes generation logic implemented in PowerShell.

### `Prepare`

- If `preparePsScript` is configured, the plugin calls `RunScript("Prepare", $false, <script>)`.
- Use this to perform build, packaging, or file preparation steps.

### `Publish`

- If `publishPsScript` is configured, the plugin calls `RunScript("Publish", $true, <script>)`.

---

## Examples

### Run a prepare script with placeholders

```json
{
  "plugins": [
    [
      "@ps-semantic-release/Exec",
      {
        "preparePsScript": "create-dist.ps1 -NoProfile -ExecutionPolicy Bypass {NextRelease.Version}"
      }
    ]
  ]
}
```

---

## Logging and messages

- Logs start and completion for each step executed via `RunScript`.
- Logs a warning and skips execution when `haltDryRun` is true and `Context.DryRun` is true.
- Logs the exact script file and expanded arguments before execution.
- Throws clear, actionable errors for:
  - Missing `.ps1` token in the configured command.
  - Script file not found on disk.
  - Non-zero script exit codes.
  - General execution failures with the underlying error message.
