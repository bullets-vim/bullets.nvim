# list-renumbering Specification

## Purpose

Renumber ordered list items while preserving list boundaries, nesting, wrapped lines, and non-ordered list items.

## Requirements

### Requirement: Renumber ordered list items

The plugin SHALL renumber ordered list items in sequence when renumbering is triggered.

#### Scenario: Renumber selected list {#RN-001}

- GIVEN a selected list contains out-of-order numeric markers
- WHEN renumbering is triggered
- THEN numeric markers are rewritten in ascending sequence

#### Scenario: Renumber list with checkboxes {#RN-002}

- GIVEN a list contains ordered items and checkbox items
- WHEN renumbering is triggered
- THEN ordered items are renumbered
- AND checkbox items are preserved

### Requirement: Renumber nested lists

The plugin SHALL renumber nested ordered list items independently by outline level.

#### Scenario: Renumber nested list {#RN-003}

- GIVEN a nested list contains multiple ordered marker styles
- WHEN renumbering is triggered from the list
- THEN ordered markers are normalized within their nesting context

#### Scenario: Visually renumber nested list {#RN-004}

- GIVEN a visual selection contains nested ordered marker styles
- WHEN visual renumbering is triggered
- THEN ordered markers inside the selection are normalized within their nesting context
