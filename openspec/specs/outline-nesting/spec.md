# outline-nesting Specification

## Purpose

Promote, demote, and auto-indent list items according to configured outline levels.

## Requirements

### Requirement: Promote and demote a single list item

The plugin SHALL move a list item up or down one outline level while preserving list ordering semantics.

#### Scenario: Demote one outline level {#ON-001}

- GIVEN the current line is a list item
- WHEN demotion is triggered
- THEN the item moves to the next configured outline level

#### Scenario: Promote one outline level {#ON-002}

- GIVEN the current line is a nested list item
- WHEN promotion is triggered
- THEN the item moves to the parent outline level

#### Scenario: Demote empty continued item {#ON-011}

- GIVEN the current line is an empty continued list item
- WHEN demotion is triggered and text is inserted
- THEN the inserted item uses the next configured child outline level

#### Scenario: Promote empty continued item {#ON-012}

- GIVEN the current line is an empty continued nested list item
- WHEN promotion is triggered and text is inserted
- THEN the inserted item uses the parent outline level

#### Scenario: Remove marker at top level {#ON-003}

- GIVEN the current line is a top-level list item
- WHEN promotion is triggered
- THEN the marker is removed from the line

### Requirement: Respect configured outline levels

The plugin SHALL use `outline_levels` to choose marker styles when changing nesting depth.

#### Scenario: Custom outline levels {#ON-004}

- GIVEN `outline_levels` is configured
- WHEN list items are promoted or demoted
- THEN marker styles follow the configured outline sequence

#### Scenario: Demote beyond configured levels {#ON-005}

- GIVEN the current marker is already at the last standard outline level
- WHEN demotion is triggered
- THEN the item keeps the last standard marker style at a deeper indentation

### Requirement: Change visual ranges

The plugin SHALL promote or demote every list item in a visual range.

#### Scenario: Promote visual range {#ON-006}

- GIVEN a visual range contains nested list items
- WHEN visual promotion is triggered
- THEN each selected list item moves to the parent outline level

#### Scenario: Demote visual range {#ON-007}

- GIVEN a visual range contains list items
- WHEN visual demotion is triggered
- THEN each selected list item moves to the next configured outline level

### Requirement: Auto-indent children after colons

The plugin SHALL insert child list items after continued list items ending in a colon when `auto_indent_after_colon` is enabled.

#### Scenario: Halfwidth colon child item {#ON-008}

- GIVEN colon auto indentation is enabled
- AND a continued list item ends with a halfwidth colon
- WHEN bullet insertion is triggered from that item
- THEN the next inserted list item is indented as a child item

#### Scenario: Fullwidth colon child item {#ON-009}

- GIVEN colon auto indentation is enabled
- AND a continued list item ends with a fullwidth colon
- WHEN bullet insertion is triggered from that item
- THEN the next inserted list item is indented as a child item

#### Scenario: Colon auto indentation disabled {#ON-010}

- GIVEN colon auto indentation is disabled
- AND a continued list item ends with a colon
- WHEN bullet insertion is triggered from that item
- THEN the next inserted list item remains at the current outline level
