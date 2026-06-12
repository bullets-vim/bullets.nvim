# Async And Performance

## Jobs And Processes

- Centralize process execution behind one module. Build argv arrays; avoid shell strings unless shell behavior is required.
- Normalize cwd, env, stdin, stdout, stderr, timeout, and locale in that boundary.
- Treat every job as cancellable. Kill superseded jobs and close handles, pipes, and timers.
- Schedule UI updates back onto the main loop. Never update buffers/windows from unsafe callbacks.
- Check `changedtick`, buffer validity, and request generation before applying async results.

## Timers And Watchers

- Debounce or throttle high-frequency events: `TextChanged`, `CursorMoved`, filesystem watchers, `DirChanged`, diagnostics, and git updates.
- Store timer/watcher handles and stop/close them on detach, setup rebuild, or exit.
- Account for platform quirks, especially filesystem watchers and process behavior on Windows.

## Hot Paths

- Avoid scanning full buffers, filesystem trees, git state, or treesitter data in render/statusline/statuscolumn callbacks.
- Cache expensive calculations and invalidate deliberately on events that actually change the data.
- Add big-file gates and per-buffer feature disablement for expensive UI features.
- Avoid repeated `require()` or dynamic module discovery in tight loops unless cached.

## Race Patterns To Review

- Async formatter writes after the user edits the buffer.
- Detached buffer still receives timer, job, watcher, or callback results.
- Repeated setup creates duplicate autocmds or duplicate process watchers.
- Lazy-loaded mappings lose counts, modes, registers, operator-pending state, or dot-repeat behavior.
- External command output is parsed under a localized environment or unexpected working directory.
