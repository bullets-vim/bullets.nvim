# marker-recognition Specification

## Purpose

Recognize supported list marker syntaxes and avoid treating ordinary text as a list item.

## Requirements

### Requirement: Recognize configured static markers

The plugin SHALL continue static marker styles enabled by `list_item_styles`.

#### Scenario: LaTeX item marker {#MR-001}

- GIVEN the current line uses `\item`
- WHEN bullet insertion is triggered at the end of the line
- THEN the inserted line repeats the `\item` marker and spacing

#### Scenario: Pandoc marker {#MR-002}

- GIVEN the current line uses `#.`
- WHEN bullet insertion is triggered at the end of the line
- THEN the inserted line repeats the `#.` marker and spacing

#### Scenario: Org-style marker {#MR-003}

- GIVEN the current line uses a repeated `*` marker
- WHEN bullet insertion is triggered at the end of the line
- THEN the inserted line repeats the same repeated marker and spacing

#### Scenario: AsciiDoc star marker {#MR-004}

- GIVEN the current line uses an AsciiDoc nested `*` marker
- WHEN bullet insertion is triggered at the end of the line
- THEN the inserted line repeats the same marker and indentation

#### Scenario: AsciiDoc dot marker {#MR-005}

- GIVEN the current line uses an AsciiDoc `.` marker
- WHEN bullet insertion is triggered at the end of the line
- THEN the inserted line repeats the same dot marker and indentation

### Requirement: Reject non-list text

The plugin SHALL fall back to a plain newline when the current line is not a recognized list item.

#### Scenario: Decimal number text {#MR-006}

- GIVEN the current line is `3.14159 is an approximation of pi.`
- AND the cursor is at the end of the line
- WHEN bullet insertion is triggered
- THEN the inserted line contains no bullet marker

#### Scenario: Invalid roman-like text {#MR-007}

- GIVEN the current line starts with text that resembles but is not a valid roman numeral list item
- AND the cursor is at the end of the line
- WHEN bullet insertion is triggered
- THEN the inserted line contains no bullet marker

#### Scenario: Mixed-case alphabetic marker {#MR-008}

- GIVEN the current line starts with a mixed-case alphabetic marker
- AND the cursor is at the end of the line
- WHEN bullet insertion is triggered
- THEN the inserted line contains no bullet marker

#### Scenario: Alphabetic markers disabled {#MR-009}

- GIVEN `max_alpha_characters` is `0`
- AND the current line starts with an alphabetic marker
- WHEN bullet insertion is triggered
- THEN the inserted line contains no bullet marker
