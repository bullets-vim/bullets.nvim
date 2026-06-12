# Architecture

## Entrypoints

- Keep `lua/<name>.lua` thin: return an `M` table, expose public functions, and delegate heavy work to focused modules.
- Let `require()` define API/defaults only. Avoid commands, autocmds, keymaps, timers, or global mutation before `setup()` unless the plugin intentionally uses a Vim runtime `plugin/` file.
- Runtime `plugin/` files should not clobber explicit user setup. If they call default `setup()`, guard it with setup state so later or earlier user config is not reset.
- Version-gate and dependency-gate early in `setup()` with actionable errors.
- Make repeated `setup()` safe: reject, no-op, or rebuild deliberately. Never silently duplicate autocmds, commands, watchers, or keymaps.

## Module Boundaries

- Split larger plugins by concern: `config`, `health`, `util`, `log`, `async`, `runner`, `actions`, `cli`, `ui`, `git` or domain-specific modules.
- For focused plugins, a `local Public = {}` plus `local H = {}` private-helper pattern is valid and keeps APIs obvious.
- Keep command parsing and UI adapters separate from core logic so Lua APIs can be tested directly.
- Lazy `__index` module loading is acceptable for documented submodules, but do not hide expensive or surprising side effects behind ordinary field access.

## Public API

- Annotate public functions and option tables with LuaCATS/EmmyLua types.
- Keep public names stable and small. Put compatibility shims behind explicit deprecation warnings only when there are real external users.
- Prefer option tables over long positional argument lists for APIs that may evolve.
- Return errors or invoke callbacks consistently; do not mix `error()`, notifications, and silent returns for the same failure class.

## State

- Keep mutable state module-local unless users need it. Expose read-only status helpers instead of raw tables.
- Store buffer-specific state by buffer number and clean it up on detach or wipeout.
- Avoid global variables except intentional `v:lua` integration points, and document those globals.
