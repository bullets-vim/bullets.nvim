# Agent Notes

## OpenSpec

OpenSpec specs live under `openspec/specs/<capability>/spec.md`. Keep specs split by user-facing capability instead of by Lua module or test file.

Every test-backed scenario heading must have a stable ID in the form `{#ABC-001}`. Tests should reference scenarios with Busted-style tags in the test name:

```lua
it('continues a bullet #LC-001', function()
  -- test body
end)
```

A scenario can be covered by multiple tests. Use the same scenario tag on each relevant test when several examples are needed for one requirement.

Use `mise run openspec:check` to validate OpenSpec artifacts and enforce spec/test links. This checks that every scenario has an ID, every scenario ID is covered by at least one test tag, and every test tag points to an existing scenario.

Useful OpenSpec coverage/report tasks:

```sh
mise run spec:coverage
mise run spec:list
mise run spec:uncovered
mise run spec:untested
mise run test:pending
mise run test:unspecified
```

Use `mise run spec:coverage --min-coverage-percent 100` to enforce full scenario coverage. Add `--json` for machine-readable output.
Pending tests are listed by `mise run test:unspecified` when untagged, but pending tests do not count as spec coverage.

Run one scenario's tagged tests with:

```sh
mise run test:spec LC-001
```

The `test:spec` task declares its `<scenario_id>` argument with mise `usage` metadata and completes possible IDs by ripgrepping `openspec/specs`.

Before implementing behavior changes, update or add the relevant OpenSpec scenario first, then add tests tagged with the scenario ID.
