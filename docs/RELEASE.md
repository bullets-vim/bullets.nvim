# Release

Releases are managed by [release-please](https://github.com/googleapis/release-please) through
`.github/workflows/release.yml`.

The workflow runs on pushes to `main`. It expects a repository secret named
`RELEASE_PLEASE_GITHUB_TOKEN`.

## Token

Use a fine-grained GitHub personal access token scoped only to `bullets-vim/bullets.nvim` with a 90-day
expiration.

GitHub's fine-grained token URL parameters can prefill the resource owner, expiration, and permissions, but
GitHub does not document a URL parameter for selecting one specific repository. After opening this URL, choose
**Only select repositories** and select `bullets-vim/bullets.nvim` before generating the token:

https://github.com/settings/personal-access-tokens/new?name=bullets.nvim%20release-please&description=release-please%20for%20bullets-vim%2Fbullets.nvim&target_name=bullets-vim&expires_in=90&contents=write&pull_requests=write&issues=write

Required repository permissions:

| Permission    | Access         |
| ------------- | -------------- |
| Contents      | Read and write |
| Pull requests | Read and write |
| Issues        | Read and write |

`Metadata: Read-only` is added automatically. Do not grant broader permissions unless release-please starts
updating workflow files, in which case the token also needs `Workflows: Read and write`.

The `Issues` permission is for labeling release PRs; GitHub manages PR labels through the Issues API.

Store the generated token as the repository secret:

```sh
gh secret set RELEASE_PLEASE_GITHUB_TOKEN --repo bullets-vim/bullets.nvim
```

Paste the token when prompted.

## Release Flow

1. Merge conventional commits to `main`.
2. The release workflow opens or updates a release PR.
3. Merge the release PR when ready.
4. release-please creates the GitHub release and tag.
