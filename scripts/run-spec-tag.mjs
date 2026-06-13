#!/usr/bin/env node

import fs from 'node:fs';
import path from 'node:path';
import process from 'node:process';
import { spawnSync } from 'node:child_process';

const tag = process.argv[2];

if (!tag) {
  console.error('Usage: node scripts/run-spec-tag.mjs <SPEC_ID>');
  process.exit(2);
}

const root = process.cwd();
const testRoot = path.join(root, 'test');
const plenaryPath = process.env.PLENARY_PATH || '/tmp/plenary.nvim';

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

if (!fs.existsSync(plenaryPath)) {
  const clone = spawnSync('git', ['clone', '--depth=1', 'https://github.com/nvim-lua/plenary.nvim', plenaryPath], {
    stdio: 'inherit',
  });
  if (clone.status !== 0) {
    process.exit(clone.status ?? 1);
  }
}

const testFiles = walk(testRoot, file => file.endsWith('_spec.lua')).filter(file => {
  return fs.readFileSync(file, 'utf8').includes(`#${tag}`);
});

if (testFiles.length === 0) {
  console.error(`No tests tagged #${tag}`);
  process.exit(1);
}

let status = 0;

for (const file of testFiles) {
  const relativeFile = path.relative(root, file);
  const result = spawnSync(
    'nvim',
    [
      '--headless',
      '-n',
      '-c',
      `set rtp+=.,${plenaryPath} | runtime plugin/plenary.vim | runtime plugin/bullets.lua`,
      '--noplugin',
      '-c',
      'luafile scripts/plenary-tag-runner.lua',
    ],
    {
      stdio: 'inherit',
      env: {
        ...process.env,
        SPEC_FILE: relativeFile,
        SPEC_TAG: tag,
      },
    }
  );

  if (result.status !== 0) {
    status = result.status ?? 1;
  }
}

process.exit(status);
