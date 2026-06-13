# Development

## Stacked PRs

Use the local `stack` CLI for stacked PR maintenance in this repository. It is built for squash-merge
repositories where merged branches are deleted, so Git ancestry alone cannot preserve stack intent.

Use plain `git` for normal editing and commits. Use `stack` for stack inspection, PR-base syncing, safe
merges, and undo workflows.

Common commands:

```sh
stack status
stack guide
stack sync --dry-run
stack sync
stack sync --keep-going
stack merge
stack merge --apply
stack merge --auto
stack history
stack undo
stack undo --apply
```

Preferred stacked PR flow:

```sh
gh pr create --base main --head stack-a
gh pr create --base stack-a --head stack-b
stack sync --dry-run
stack sync
```

Use `stack sync --dry-run` before mutating stack metadata or retargeting PRs. If the preview is correct,
run `stack sync` to infer PR-base stack links, repair descendants, retarget PRs, and refresh stack blocks in
PR descriptions.

Use `stack merge` without flags as a dry run. Add `--apply` only after the plan looks correct. Use
`stack merge --auto` when GitHub auto-merge should land the root PR and then repair descendants.

If a stack operation needs to be reverted, inspect the latest repair journal first:

```sh
stack history
stack undo
stack undo --apply
```

Do not edit `.git/stack/state.json` by hand. If local stack metadata looks stale, run `stack sync --dry-run`
and then `stack sync` if the inferred stack is correct.
