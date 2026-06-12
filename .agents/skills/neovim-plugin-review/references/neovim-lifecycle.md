# Neovim Lifecycle

## Setup Registration

- Create named augroups with `clear = true` for global setup registration, or explicit IDs for per-buffer lifecycle.
- Add `desc` to autocmds and commands when supported.
- Use `once = true` for one-shot lazy initialization and buffer-local autocmds for buffer-owned behavior.
- Guard callbacks with buffer validity, loaded state, `buftype`, file name, file size, and plugin disable flags before doing work.

## Buffers And Attach

- Make attach and detach idempotent. Re-attaching should refresh or no-op, not leak extmarks, signs, timers, or autocmds.
- Check user `on_attach` callbacks and respect `false` returns when supported.
- Clean buffer state on `BufWipeout`, detach, file rename, or feature disable.
- Use namespaces for extmarks/signs/highlights, and clear only the plugin's own namespace.

## Commands And Keymaps

- Define user commands in setup or `plugin/` entrypoints, with `nargs`, `range`, `bang`, `complete`, and validation matching real usage.
- Keep CLI parsing separate from core action functions.
- For operator-pending, expression, repeatable, or dot-repeat mappings, test actual key behavior in Neovim.
- For fallback mappings, prefer expression mappings that return the original key sequence. Calling `nvim_feedkeys()` from a non-expression mapping can fail to behave like native typing, especially in Insert mode.
- Do not map built-in editing keys to unimplemented stubs. Shadowing `o`, `<CR>`, `>>`, `<<`, `<C-t>`, or `<C-d>` is a behavioral regression unless the replacement is complete.
- Preserve lazy-loading intent: replay commands, feed keys, or re-fire autocmds only when necessary and safely bounded.

## Health

- Provide `lua/<plugin>/health.lua` when the plugin has setup state, external tools, optional integrations, generated files, or common misconfiguration.
- Check Neovim version, setup called/not called, dependency executables and versions, log paths, lazy-loading mistakes, and current-buffer status.
- Health output should be actionable, not just diagnostic.

## Runtime Files

- Keep `plugin/*.lua` or `plugin/*.vim` minimal. It should register commands or bootstrap only what must exist before `setup()`.
- Keep generated `doc/*.txt` in sync with Lua annotations or source docs when the project uses generation.
