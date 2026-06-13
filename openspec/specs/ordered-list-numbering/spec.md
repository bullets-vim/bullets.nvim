# ordered-list-numbering Specification

## Purpose

Continue ordered list markers with the correct sequence, marker style, casing, and padding.

## Requirements

### Requirement: Continue numeric markers

The plugin SHALL continue numeric list items by incrementing the current marker and preserving the closure style.

#### Scenario: Numeric marker increments {#OLN-001}

- GIVEN the current line is a numeric list item using `.` or `)` as the closure
- WHEN bullet insertion is triggered at the end of the line
- THEN the inserted line uses the next numeric marker with the same closure style

### Requirement: Apply ordered marker padding

The plugin SHALL apply `pad_right` when continuing ordered list markers.

#### Scenario: Pad ordered marker {#OLN-002}

- GIVEN right padding is enabled
- AND continuing an ordered list changes marker width
- WHEN bullet insertion is triggered
- THEN the inserted marker is padded to preserve the prior prefix width when possible

#### Scenario: Disable ordered marker padding {#OLN-003}

- GIVEN right padding is disabled
- AND continuing an ordered list changes marker width
- WHEN bullet insertion is triggered
- THEN the inserted marker uses normal single-space marker spacing

### Requirement: Continue alphabetic markers

The plugin SHALL continue alphabetic list markers while preserving case and respecting `max_alpha_characters`.

#### Scenario: Uppercase alphabetic marker increments {#OLN-004}

- GIVEN the current line is an uppercase alphabetic list item
- WHEN bullet insertion is triggered at the end of the line
- THEN the inserted line uses the next uppercase alphabetic marker

#### Scenario: Lowercase alphabetic marker increments {#OLN-005}

- GIVEN the current line is a lowercase alphabetic list item
- WHEN bullet insertion is triggered at the end of the line
- THEN the inserted line uses the next lowercase alphabetic marker

#### Scenario: Alphabetic marker rolls over after z {#OLN-010}

- GIVEN the current line is an alphabetic list item ending near `z`
- WHEN bullet insertion is triggered repeatedly
- THEN the inserted markers roll over to multi-letter alphabetic markers with the same case

#### Scenario: Alphabetic marker length limit {#OLN-006}

- GIVEN the next alphabetic marker would exceed `max_alpha_characters`
- WHEN bullet insertion is triggered
- THEN the inserted line contains no bullet marker

### Requirement: Continue roman numeral markers

The plugin SHALL continue roman numeral list markers while preserving case and respecting `enable_roman_list`.

#### Scenario: Uppercase roman marker increments {#OLN-007}

- GIVEN roman list support is enabled
- AND the current line is an uppercase roman numeral list item
- WHEN bullet insertion is triggered at the end of the line
- THEN the inserted line uses the next uppercase roman numeral marker

#### Scenario: Lowercase roman marker increments {#OLN-008}

- GIVEN roman list support is enabled
- AND the current line is a lowercase roman numeral list item
- WHEN bullet insertion is triggered at the end of the line
- THEN the inserted line uses the next lowercase roman numeral marker

#### Scenario: Roman markers disabled {#OLN-009}

- GIVEN roman list support is disabled
- AND the current line is a roman numeral list item
- WHEN bullet insertion is triggered
- THEN the inserted line contains no roman numeral marker
