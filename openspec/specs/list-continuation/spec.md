# list-continuation Specification

## Purpose

Continue, split, or finish list items when users trigger bullet insertion from insert or normal mode.

## Requirements

### Requirement: Continue unordered list items

The plugin SHALL insert a matching unordered list item when bullet insertion is triggered at the end of a recognized unordered list item.

#### Scenario: Standard unordered marker {#LC-001}

- GIVEN the current line is `- first item`
- AND the cursor is at the end of the line
- WHEN bullet insertion is triggered
- THEN the buffer contains a following line beginning with the `-` marker and its spacing

### Requirement: Preserve editing intent away from end of line

The plugin SHALL split the current line without adding a bullet marker when bullet insertion is triggered before the end of a line.

#### Scenario: Cursor inside list item text {#LC-002}

- GIVEN the current line is a recognized list item
- AND the cursor is not at the end of the line
- WHEN bullet insertion is triggered
- THEN the line is split at the cursor position
- AND no additional bullet marker is inserted

### Requirement: Finish empty list items

The plugin SHALL handle an empty continued list item according to `delete_last_bullet_if_empty`.

#### Scenario: Delete empty item {#LC-003}

- GIVEN `delete_last_bullet_if_empty` is `1`
- AND the current line is an empty list item
- WHEN bullet insertion is triggered
- THEN the empty list item is removed
- AND the cursor remains on the same line

#### Scenario: Promote empty item {#LC-004}

- GIVEN `delete_last_bullet_if_empty` is `2`
- AND the current line is an empty nested list item
- WHEN bullet insertion is triggered
- THEN the empty list item is promoted one outline level

#### Scenario: Keep empty item {#LC-005}

- GIVEN `delete_last_bullet_if_empty` is `0`
- AND the current line is an empty list item
- WHEN bullet insertion is triggered
- THEN the empty list item remains

### Requirement: Apply continuation spacing

The plugin SHALL apply configured line spacing when inserting continued list items.

#### Scenario: Insert configured line spacing {#LC-006}

- GIVEN `line_spacing` is greater than `1`
- AND the current line is a recognized list item
- WHEN bullet insertion is triggered
- THEN the inserted list item is separated from the current item by the configured number of lines
