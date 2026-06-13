#!/usr/bin/env node

import fs from 'node:fs';
import path from 'node:path';
import process from 'node:process';

const root = process.cwd();
const specRoot = path.join(root, 'openspec', 'specs');
const testRoot = path.join(root, 'test');
const idPattern = /^[A-Z][A-Z0-9]+-\d{3}$/;

function walk(dir, predicate) {
  const results = [];
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      results.push(...walk(fullPath, predicate));
    } else if (predicate(fullPath)) {
      results.push(fullPath);
    }
  }
  return results.sort();
}

function relative(file) {
  return path.relative(root, file);
}

const specIds = new Map();
const specFiles = new Map();
const duplicateSpecIds = [];
const missingScenarioIds = [];

for (const file of walk(specRoot, file => file.endsWith('.md'))) {
  const specFile = relative(file);
  specFiles.set(specFile, []);
  const lines = fs.readFileSync(file, 'utf8').split('\n');
  for (const [index, line] of lines.entries()) {
    if (line.startsWith('#### Scenario:') && !line.includes('{#')) {
      missingScenarioIds.push(`Scenario at ${relative(file)}:${index + 1} has no ID`);
      continue;
    }

    const match = line.match(/^#### Scenario: .+ \{#([^}]+)\}$/);
    if (!match) {
      continue;
    }

    const id = match[1];
    const location = `${relative(file)}:${index + 1}`;
    if (!idPattern.test(id)) {
      duplicateSpecIds.push(`Invalid scenario ID ${id} at ${location}`);
    } else if (specIds.has(id)) {
      duplicateSpecIds.push(`Duplicate scenario ID ${id} at ${location}; first seen at ${specIds.get(id)}`);
    } else {
      specIds.set(id, location);
      specFiles.get(specFile).push(id);
    }
  }
}

const testRefs = new Map();
const invalidRefs = [];
const untaggedActiveTests = [];
const untaggedPendingTests = [];
const pendingTests = [];

function addTestRef(id, location) {
  if (!idPattern.test(id)) {
    invalidRefs.push(`Invalid test spec reference ${id} at ${location}`);
    return;
  }
  if (!testRefs.has(id)) {
    testRefs.set(id, []);
  }
  testRefs.get(id).push(location);
}

for (const file of walk(testRoot, file => file.endsWith('.lua'))) {
  const lines = fs.readFileSync(file, 'utf8').split('\n');
  for (const [index, line] of lines.entries()) {
    const location = `${relative(file)}:${index + 1}`;
    const testName = line.match(/\b(it|test|spec|pending)\s*\(\s*(['"])(.*?)\2/);
    if (!testName) {
      continue;
    }

    const isPending = testName[1] === 'pending';
    if (isPending) {
      pendingTests.push(`${location} ${testName[3]}`);
    }

    let tagCount = 0;
    for (const tagMatch of testName[3].matchAll(/#([A-Z][A-Z0-9]+-\d{3})\b/g)) {
      tagCount += 1;
      if (!isPending) {
        addTestRef(tagMatch[1], location);
      }
    }
    if (tagCount === 0) {
      if (isPending) {
        untaggedPendingTests.push(`Pending test at ${location} has no spec ID tag`);
      } else {
        untaggedActiveTests.push(`Active test at ${location} has no spec ID tag`);
      }
    }
  }
}

const unreferenced = [...specIds.keys()].filter(id => !testRefs.has(id));
const unknownRefs = [...testRefs.keys()].filter(id => !specIds.has(id));
const uncoveredSpecFiles = [...specFiles.entries()]
  .filter(([, ids]) => ids.length === 0 || ids.every(id => !testRefs.has(id)))
  .map(([file]) => file);
const errors = [
  ...missingScenarioIds,
  ...duplicateSpecIds,
  ...invalidRefs,
  ...untaggedActiveTests,
  ...unreferenced.map(id => `Scenario ${id} at ${specIds.get(id)} has no test reference`),
  ...unknownRefs.flatMap(id => testRefs.get(id).map(location => `Test reference ${id} at ${location} has no matching scenario`)),
];

function percent(numerator, denominator) {
  return `${percentNumber(numerator, denominator).toFixed(1)}%`;
}

function percentNumber(numerator, denominator) {
  if (denominator === 0) {
    return 100;
  }
  return (numerator / denominator) * 100;
}

function printList(title, items, emptyMessage) {
  console.log(title);
  if (items.length === 0) {
    console.log(emptyMessage);
    return;
  }
  for (const item of items) {
    console.log(`- ${item}`);
  }
}

const mode = process.argv[2] || 'check';

if (mode === 'coverage') {
  const args = process.argv.slice(3);
  let json = false;
  let minCoveragePercent = null;

  for (let index = 0; index < args.length; index += 1) {
    const arg = args[index];
    if (arg === '--json') {
      json = true;
    } else if (arg === '--min-coverage-percent') {
      const value = args[index + 1];
      if (value === undefined) {
        console.error('--min-coverage-percent requires a value');
        process.exit(2);
      }
      minCoveragePercent = Number(value);
      index += 1;
    } else {
      console.error(`Unknown coverage option: ${arg}`);
      process.exit(2);
    }
  }

  if (minCoveragePercent !== null && !Number.isFinite(minCoveragePercent)) {
    console.error('--min-coverage-percent must be a number');
    process.exit(2);
  }

  const coveredScenarioCount = [...specIds.keys()].filter(id => testRefs.has(id)).length;
  const coveredSpecFileCount = [...specFiles.values()].filter(ids => ids.length > 0 && ids.some(id => testRefs.has(id))).length;
  const testRefCount = [...testRefs.values()].reduce((total, locations) => total + locations.length, 0);
  const scenarioCoveragePercent = percentNumber(coveredScenarioCount, specIds.size);
  const specFileCoveragePercent = percentNumber(coveredSpecFileCount, specFiles.size);

  const result = {
    scenarioCoveragePercent,
    coveredScenarios: coveredScenarioCount,
    totalScenarios: specIds.size,
    specFileCoveragePercent,
    coveredSpecFiles: coveredSpecFileCount,
    totalSpecFiles: specFiles.size,
    taggedTests: testRefCount,
    uncoveredScenarios: unreferenced,
    uncoveredSpecFiles,
    untaggedActiveTests,
  };

  if (json) {
    console.log(JSON.stringify(result, null, 2));
  } else {
    console.log(`Spec coverage: ${percent(coveredScenarioCount, specIds.size)} (${coveredScenarioCount}/${specIds.size} scenarios)`);
    console.log(`Spec file coverage: ${percent(coveredSpecFileCount, specFiles.size)} (${coveredSpecFileCount}/${specFiles.size} spec files)`);
    console.log(`Tagged tests: ${testRefCount}`);
  }

  if (minCoveragePercent !== null && scenarioCoveragePercent < minCoveragePercent) {
    console.error(
      `Spec coverage ${scenarioCoveragePercent.toFixed(1)}% is below required minimum ${minCoveragePercent.toFixed(1)}%`
    );
    process.exit(1);
  }

  process.exit(0);
}

if (mode === 'uncovered-spec-files') {
  printList('Spec files with no test coverage:', uncoveredSpecFiles, 'All spec files have test coverage.');
  process.exit(0);
}

if (mode === 'untested-scenarios') {
  printList('Scenarios with no test coverage:', unreferenced.map(id => `${id} at ${specIds.get(id)}`), 'All scenarios have test coverage.');
  process.exit(0);
}

if (mode === 'untagged-tests') {
  const unspecifiedTests = [...untaggedActiveTests, ...untaggedPendingTests];
  printList('Tests with no related spec tag:', unspecifiedTests, 'All tests have spec tags.');
  process.exit(0);
}

if (mode === 'pending-tests') {
  printList('Pending tests:', pendingTests, 'No pending tests.');
  process.exit(0);
}

if (mode !== 'check') {
  console.error(`Unknown mode: ${mode}`);
  process.exit(2);
}

if (errors.length > 0) {
  console.error('Spec/test link check failed:');
  for (const error of errors) {
    console.error(`- ${error}`);
  }
  process.exit(1);
}

console.log(`Spec/test links valid: ${specIds.size} scenarios, ${testRefs.size} referenced IDs`);
