# checkbox-state Specification

## Purpose

Continue, toggle, and recompute checkbox list state across nested list trees.

## Requirements

### Requirement: Continue checkbox list items

The plugin SHALL continue checkbox list items with an unchecked checkbox marker.

#### Scenario: Unchecked checkbox continuation {#CS-001}

- GIVEN the current line is an unchecked checkbox item
- WHEN bullet insertion is triggered
- THEN the inserted line includes an unchecked checkbox marker

#### Scenario: Alternative checkbox bullet marker {#CS-002}

- GIVEN the current line is a checkbox item using a non-`-` bullet marker
- WHEN bullet insertion is triggered
- THEN the inserted line preserves the bullet marker and includes an unchecked checkbox marker

#### Scenario: Checked checkbox continuation {#CS-003}

- GIVEN the current line is a checked checkbox item
- WHEN bullet insertion is triggered
- THEN the inserted line includes an unchecked checkbox marker

### Requirement: Toggle checkbox markers

The plugin SHALL toggle recognized checkbox markers according to configured marker order.

#### Scenario: Toggle recognized markers {#CS-004}

- GIVEN the current line contains a recognized checkbox marker
- WHEN checkbox toggle is triggered
- THEN the marker advances to the next configured state

#### Scenario: Custom checkbox markers {#CS-005}

- GIVEN custom checkbox markers are configured
- WHEN checkbox items are toggled or inserted
- THEN the configured markers are used for checkbox state

### Requirement: Propagate nested checkbox state

The plugin SHALL update related parent and child checkboxes when nested checkbox state changes.

#### Scenario: Toggle adjusts parents {#CS-006}

- GIVEN a nested child checkbox is toggled
- WHEN checkbox propagation completes
- THEN parent checkbox states reflect their children

#### Scenario: Toggle adjusts children {#CS-007}

- GIVEN a parent checkbox is toggled
- WHEN checkbox propagation completes
- THEN child checkbox states follow the parent state

#### Scenario: Blank separator stops propagation {#CS-008}

- GIVEN a blank line separates checkbox groups
- WHEN a checkbox before the blank line is toggled
- THEN checkbox items after the blank line are not updated

#### Scenario: Partial completion states {#CS-009}

- GIVEN a checkbox tree has a mix of checked and unchecked children
- WHEN checkbox state is recomputed
- THEN parent checkbox markers indicate partial completion

### Requirement: Recompute checkbox state

The plugin SHALL recompute nested checkbox state on demand.

#### Scenario: Recursive recompute {#CS-010}

- GIVEN a nested checkbox tree has stale parent markers
- WHEN recompute is triggered
- THEN every parent checkbox marker reflects its descendant checkbox state

#### Scenario: Recompute after reindent {#CS-011}

- GIVEN checkbox item indentation has changed
- WHEN recompute is triggered
- THEN parent checkbox markers reflect the new tree structure

#### Scenario: Skip-level checkbox tree {#CS-012}

- GIVEN checkbox items appear under non-checkbox intervening list items
- WHEN recompute is triggered
- THEN checkbox roots and descendants are recomputed according to indentation
