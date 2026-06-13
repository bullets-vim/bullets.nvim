# wrapped-lines Specification

## Purpose

Continue list items from wrapped content lines only when the wrapped line belongs to a preceding list item.

## Requirements

### Requirement: Continue from wrapped list content

The plugin SHALL continue the owning list item when bullet insertion is triggered from a wrapped content line.

#### Scenario: Wrapped content continuation {#WL-001}

- GIVEN the current line is wrapped content belonging to the preceding list item
- AND wrapped line support is enabled
- WHEN bullet insertion is triggered
- THEN the inserted line starts a new list item at the owning list item's level

### Requirement: Respect wrapped line configuration

The plugin SHALL not continue wrapped list items when wrapped line support is disabled.

#### Scenario: Wrapped support disabled {#WL-002}

- GIVEN wrapped line support is disabled
- AND the current line is wrapped content belonging to the preceding list item
- WHEN bullet insertion is triggered
- THEN the inserted line contains no bullet marker

### Requirement: Stop wrapped continuation at separators

The plugin SHALL not continue a list item through blank or whitespace-only separator lines.

#### Scenario: Blank separator {#WL-003}

- GIVEN a blank line separates the current line from the preceding list item
- WHEN bullet insertion is triggered
- THEN the inserted line contains no bullet marker

#### Scenario: Whitespace-only separator {#WL-004}

- GIVEN a whitespace-only line separates the current line from the preceding list item
- WHEN bullet insertion is triggered
- THEN the inserted line contains no bullet marker
