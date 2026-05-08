import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';

import { runSddParityCheck } from '../sdd-parity-runner.mjs';

const FIXTURES_ROOT = path.resolve(process.cwd(), 'scripts', '__fixtures__', 'sdd-parity');
const VALID_ROOT = path.join(FIXTURES_ROOT, 'valid');
const DRIFTED_ROOT = path.join(FIXTURES_ROOT, 'drifted');

function makeTempFixtureCopy(name) {
  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), `sdd-parity-${name}-`));
  fs.cpSync(VALID_ROOT, tempDir, { recursive: true });
  return tempDir;
}

function applyDrift(tempDir, driftCategory) {
  const driftDir = path.join(DRIFTED_ROOT, driftCategory);
  const entries = fs.readdirSync(driftDir);
  for (const entry of entries) {
    const sourcePath = path.join(driftDir, entry);
    if (entry === 'remove.txt') {
      const removals = fs
        .readFileSync(sourcePath, 'utf8')
        .split('\n')
        .map((line) => line.trim())
        .filter(Boolean);

      for (const fileName of removals) {
        fs.rmSync(path.join(tempDir, fileName));
      }
      continue;
    }

    fs.copyFileSync(sourcePath, path.join(tempDir, entry));
  }
}

test('passes against a valid command set fixture', () => {
  const fixtureDir = makeTempFixtureCopy('valid');
  const report = runSddParityCheck({ commandDir: fixtureDir });

  assert.equal(report.status, 'pass');
  assert.equal(report.summary.failures_total, 0);
  assert.equal(report.checked_files.length, 12);
});

test('scenario: missing required command file fails', () => {
  const fixtureDir = makeTempFixtureCopy('missing-file');
  applyDrift(fixtureDir, 'missing-file');
  const report = runSddParityCheck({ commandDir: fixtureDir });

  assert.equal(report.status, 'fail');
  assert.ok(report.failures.some((failure) => failure.rule_id === 'required-command-presence'));
});

test('scenario: missing placeholder fails with actionable message', () => {
  const fixtureDir = makeTempFixtureCopy('missing-placeholder');
  applyDrift(fixtureDir, 'missing-placeholder');
  const report = runSddParityCheck({ commandDir: fixtureDir });

  const placeholderFailure = report.failures.find(
    (failure) => failure.rule_id === 'placeholder-contract.required',
  );

  assert.ok(placeholderFailure);
  assert.match(placeholderFailure.message, /Missing placeholder/);
});

test('scenario: missing persistence mode guidance fails', () => {
  const fixtureDir = makeTempFixtureCopy('missing-mode-guidance');
  applyDrift(fixtureDir, 'missing-mode-guidance');
  const report = runSddParityCheck({ commandDir: fixtureDir });

  assert.ok(report.failures.some((failure) => failure.rule_id === 'persistence-modes.required'));
});

test('scenario: missing result field is reported', () => {
  const fixtureDir = makeTempFixtureCopy('missing-result-field');
  applyDrift(fixtureDir, 'missing-result-field');
  const report = runSddParityCheck({ commandDir: fixtureDir });

  assert.ok(report.failures.some((failure) => failure.rule_id === 'result-contract.required-fields'));
});

test('scenario: meta command missing state guidance fails', () => {
  const fixtureDir = makeTempFixtureCopy('missing-state-guidance');
  applyDrift(fixtureDir, 'missing-state-guidance');
  const report = runSddParityCheck({ commandDir: fixtureDir });

  assert.ok(report.failures.some((failure) => failure.rule_id === 'meta-state-guidance.required'));
});

test('returns payload shape expected by CI consumers', () => {
  const fixtureDir = makeTempFixtureCopy('shape');
  const report = runSddParityCheck({ commandDir: fixtureDir });

  assert.ok(report.summary);
  assert.equal(typeof report.summary.rules_total, 'number');
  assert.equal(Array.isArray(report.checked_files), true);
  assert.equal(Array.isArray(report.failures), true);
});
