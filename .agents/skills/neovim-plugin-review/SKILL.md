---
name: neovim-plugin-review
description: Review Neovim plugins for best practices, maintainability, and idiomatic Lua. Use when asked to review or improve a Neovim plugin, Lua code under lua/, plugin/, after/, ftplugin/, autoload/, doc/, tests/, or when checking setup/config APIs, autocmds, keymaps, async jobs, health checks, docs, tests, or plugin architecture.
---

# Neovim Plugin Review

Review plugins like a maintainer: start from behavior and user-facing API, then check architecture, Lua idioms, Neovim lifecycle, async/performance, and quality gates. Prioritize concrete bugs, regressions, race conditions, invalid APIs, user-state stomping, and missing tests before style preferences.

## Workflow

- Inspect the plugin shape first: entrypoints, `setup()`, public API, commands, docs, tests, and CI/tooling.
- For stacked PRs, compare each PR against its declared PR base branch, not against `main` or the stack tip.
- Compare implementation against the focused references below. Load only the files relevant to the review.
- Report findings first, ordered by severity, with file and line references. Keep praise and architecture summary brief.
- Prefer small, actionable fixes that preserve the plugin's current design unless the architecture itself is the problem.

## Reference Map

- Read `references/architecture.md` for module layout, public/private boundaries, setup idempotency, and API shape.
- Read `references/lua-config.md` for idiomatic Lua, config defaults, validation, buffer-local config, mappings, and user-state preservation.
- Read `references/neovim-lifecycle.md` for autocmds, commands, keymaps, buffers, highlights, health checks, and plugin runtime behavior.
- Read `references/async-performance.md` for jobs, timers, watchers, scheduling, race avoidance, debounce/throttle, and hot-path performance.
- Read `references/quality-gates.md` for docs, tests, formatting, type annotations, CI, release hygiene, and review checklists.

## Baseline Rules

- `require()` should be cheap and mostly side-effect free; `setup()` owns validation and registration.
- Public APIs should be typed, documented, stable, and separated from CLI/user-command parsing.
- Config should deep-copy defaults, validate user input, avoid mutating caller tables, and support runtime overrides only where behavior truly updates at runtime.
- Autocmds, timers, jobs, namespaces, extmarks, and watchers need explicit ownership and cleanup.
- UI work and notifications must be scheduled out of fast events and async callbacks when needed.
- Expensive features need guards for big files, invalid buffers, changed buffers, missing tools, and repeated setup.
- Tests should cover boundary behavior: commands, mappings, buffer attach/detach, async races, external processes, generated docs, and config validation.

## Source Models

These rules were distilled from high-quality plugins cloned under `tmp/`: `folke/lazy.nvim`, `folke/snacks.nvim`, `echasnovski/mini.nvim`, `stevearc/conform.nvim`, and `lewis6991/gitsigns.nvim`. Use them as pattern sources, not as rigid style mandates.
