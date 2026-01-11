# CI configuration

## Run `Invoke-SemanticRelease` only after tests succeed

The `Invoke-SemanticRelease` should be executed only after all tests in the CI build pass. If your CI runs multiple jobs (for example, testing on multiple OSs), make sure the semantic release step runs after all jobs succeed.

Supported CI/CD systems include:

- GitHub Actions
- GitLab Pipelines

## Authentication

### Push access to the repository

**PSSemanticRelease** needs push access to create Git tags. Set one of these environment variables in your CI:

| Variable                     | Description                                                                                                            |
| ---------------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| `GITHUB_TOKEN` or `GH_TOKEN` | GitHub [personal access token](https://help.github.com/articles/creating-a-personal-access-token-for-the-command-line) |
| `GITLAB_TOKEN` or `GL_TOKEN` | GitLab [personal access token](https://docs.gitlab.com/ce/user/profile/personal_access_tokens.html)                    |

### Authentication for plugins

Some plugins require credentials to publish packages:

| Package           | Required Variable Notes                                                    |
| ----------------- | -------------------------------------------------------------------------- |
| GitHub releases   | `GITHUB_TOKEN` or `GH_TOKEN`, used by `@ps-semantic-release/GitHub` plugin |
| GitLab releases   | `GITLAB_TOKEN` or `GL_TOKEN`, used by `@ps-semantic-release/GitLab` plugin |
| NuGet / PSGallery | `NUGET_API_KEY`, used by `@ps-semantic-release/NuGet` plugin               |

Make sure all tokens are configured as CI environment variables and not hard-coded.
