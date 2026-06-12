# Lua And Config

## Idiomatic Lua

- Prefer local functions and local aliases for hot APIs (`local api = vim.api`) when it improves clarity or hot-path cost.
- Use `vim.api`, `vim.keymap.set`, `vim.fs`, `vim.uv or vim.loop`, `vim.system` where the minimum supported Neovim version allows it.
- Use `pcall` or `xpcall` around optional integrations, file IO, dynamic `loadfile`, user callbacks, and external-tool parsing.
- Avoid mutating tables passed by users. Deep-copy defaults before merge.

## Config

- Define defaults in one place and document them near the public setup API.
- Merge with `vim.tbl_deep_extend('force', vim.deepcopy(defaults), opts or {})` or an equivalent schema-aware merge.
- Validate field types and enum values eagerly. Unknown keys should warn or error for public config schemas.
- Distinguish setup-time values from runtime values. Mappings and autocmds usually apply once; behavior flags can be read dynamically.
- For buffer-local config, compose global config, `vim.b.<plugin>_config`, and per-call options at action time.

## User State

- Do not overwrite user mappings/options unless documented and necessary.
- If creating default mappings, allow `''` or `false` to disable them and always include `desc`.
- Use highlight `default = true` or links where possible, and recreate highlights on `ColorScheme` if the plugin owns custom groups.
- Separate disabling from silencing: disabling stops behavior; silencing suppresses non-error feedback.

## Error And Notification Style

- Schedule notifications from statusline callbacks, async callbacks, fast events, and contexts where notification plugins may not be ready.
- Use `vim.notify_once` or a plugin-level dedupe when repeated failures can spam users.
- Prefix messages with the plugin name and make remediation concrete.
