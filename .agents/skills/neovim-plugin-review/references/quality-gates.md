# Quality Gates

## Tests

- Expect tests for public API behavior, config validation, commands, mappings, buffer attach/detach, async races, jobs, watchers, and generated output.
- For keymaps, include real headless Neovim key-feeding tests for fallback paths, not only direct Lua function calls.
- Use a minimal Neovim init for tests so behavior is reproducible outside a user's config.
- Clean buffers, globals, autocmds, temp dirs, and package state between tests.
- For external tools, test argv construction and error handling separately from integration tests.

## Docs

- Public setup options, commands, mappings, globals, health checks, and extension points need docs.
- Generated docs should have a check that fails on drift.
- Examples should be executable or close to executable, not broad pseudocode.
- Document intentional limitations and known edge cases instead of hiding them in comments.

## Tooling

- Look for Stylua or an equivalent formatter, luacheck or LuaCATS-aware type checking where useful, and CI across supported Neovim versions.
- Keep minimum Neovim version explicit in README/docs and enforced in code.
- CI should run tests, formatting checks, doc generation checks, and platform/tool matrix when external behavior varies.

## Review Checklist

- Does `require()` have surprising side effects?
- Can `setup()` be called twice without leaks?
- Are config defaults copied and validated?
- Are user mappings, options, highlights, and globals respected?
- Are buffers, jobs, timers, watchers, extmarks, and autocmds cleaned up?
- Are async results guarded against stale buffers and changed text?
- Are errors actionable and debug logs discoverable?
- Are tests focused on the risky boundaries of this plugin?
