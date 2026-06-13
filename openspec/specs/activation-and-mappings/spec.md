# activation-and-mappings Specification

## Purpose

Activate bullets.nvim in supported buffers, expose commands, and preserve native editing behavior when plugin mappings are disabled or not applicable.

## Requirements

### Requirement: Register user commands

The plugin SHALL register its public user commands during setup.

#### Scenario: Insert command is available {#ACT-001}

- GIVEN bullets.nvim has been set up
- WHEN Neovim checks for `:InsertNewBullet`
- THEN the command exists

### Requirement: Preserve native editing fallbacks

The plugin SHALL preserve native editing behavior when a plugin action is not applicable.

#### Scenario: Normal-mode open line fallback {#ACT-002}

- GIVEN the current line is plain text
- WHEN normal-mode `o` is used
- THEN Neovim opens a plain line below without inserting a bullet marker

#### Scenario: Insert-mode return fallback {#ACT-003}

- GIVEN the current line is plain text
- WHEN insert-mode return is used
- THEN Neovim inserts a plain newline without a bullet marker

### Requirement: Respect mapping configuration

The plugin SHALL not install default mappings when default mappings are disabled.

#### Scenario: Default mappings disabled {#ACT-004}

- GIVEN setup is called with `set_mappings = false`
- WHEN a supported buffer is opened
- THEN default normal-mode bullet mappings are not installed

### Requirement: Apply newline mapping in supported buffers

The plugin SHALL install the newline continuation mapping in configured filetypes when mappings are enabled.

#### Scenario: Insert return continues a bullet {#ACT-005}

- GIVEN the current buffer has a configured filetype
- AND the current line is a recognized bullet item
- WHEN insert-mode return is used at the end of the line
- THEN a continued bullet item is inserted
