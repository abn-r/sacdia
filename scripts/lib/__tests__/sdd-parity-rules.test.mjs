import test from 'node:test';
import assert from 'node:assert/strict';

import {
  PARITY_RULES,
  REQUIRED_COMMANDS,
  getRequiredPersistenceModes,
  getRequiredPlaceholders,
  getRequiredResultFields,
} from '../sdd-parity-rules.mjs';

test('rules include required invariant categories', () => {
  const ruleIds = PARITY_RULES.map((rule) => rule.rule_id);

  assert.deepEqual(ruleIds, [
    'required-command-presence',
    'placeholder-contract.required',
    'persistence-modes.required',
    'result-contract.required-fields',
    'meta-state-guidance.required',
  ]);
});

test('required command list covers all SDD command contracts', () => {
  assert.equal(REQUIRED_COMMANDS.length, 12);
  assert.ok(REQUIRED_COMMANDS.includes('sdd-apply.md'));
  assert.ok(REQUIRED_COMMANDS.includes('sdd-ff.md'));
});

test('placeholder requirements are command-specific', () => {
  assert.deepEqual(getRequiredPlaceholders('sdd-explore.md'), ['{workdir}', '{project}', '{argument}']);
  assert.deepEqual(getRequiredPlaceholders('sdd-init.md'), ['{workdir}', '{project}']);
});

test('persistence guidance requires all modes', () => {
  assert.deepEqual(getRequiredPersistenceModes(), ['engram', 'openspec', 'hybrid', 'none']);
});

test('result contract requires standard fields', () => {
  assert.deepEqual(getRequiredResultFields(), [
    'status',
    'executive_summary',
    'artifacts',
    'next_recommended',
  ]);
});
