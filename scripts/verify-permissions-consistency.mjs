#!/usr/bin/env node
/**
 * verify-permissions-consistency.mjs
 *
 * Cross-repo drift guard. Compares permission strings referenced in the
 * admin panel (nav-config + PERMISSION_GROUPS) against the canonical
 * backend seed (prisma/seeds/permissions.seed.sql). Fails when the admin
 * references a permission string that is not defined (or is inactive) in
 * the seed.
 *
 * Run from monorepo root:
 *   node scripts/verify-permissions-consistency.mjs            — warn only
 *   node scripts/verify-permissions-consistency.mjs --strict    — fail on any drift
 *
 * Exit 0 = consistent (default) OR strict+clean. Exit 1 = --strict + drift found.
 */

import { existsSync, readFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = resolve(__dirname, '..');

const SEED_PATH = resolve(ROOT, 'sacdia-backend/prisma/seeds/permissions.seed.sql');
const ADMIN_NAV_PATH = resolve(ROOT, 'sacdia-admin/src/components/layout/nav-config.ts');
const ADMIN_PERMS_PATH = resolve(ROOT, 'sacdia-admin/src/lib/auth/permissions.ts');

// Strings referenced by the admin UI that are UI-only virtual permissions
// (not enforced by the backend). Kept here so the CI doesn't flag them.
const ADMIN_VIRTUAL_ALLOWLIST = new Set([
  'dashboard:view',
]);

function extractFromSeed(content) {
  const lines = content.split('\n');
  const active = new Set();
  const inactive = new Set();

  let inInsertBlock = false;
  for (const line of lines) {
    const trimmed = line.trim();
    if (/^INSERT INTO permissions\b/i.test(trimmed)) {
      inInsertBlock = true;
      continue;
    }
    if (inInsertBlock && /^ON CONFLICT/i.test(trimmed)) {
      inInsertBlock = false;
      continue;
    }
    if (!inInsertBlock) continue;
    const match = /^\(\s*'([a-z_][a-z0-9_]*:[a-z_][a-z0-9_]*)'\s*,\s*'[^']*'\s*,\s*(true|false)\s*\)/i.exec(trimmed);
    if (match) {
      const [, name, activeFlag] = match;
      if (activeFlag.toLowerCase() === 'true') {
        active.add(name);
      } else {
        inactive.add(name);
      }
    }
  }

  // Honour the legacy-soft-delete UPDATE block (flips active=false after INSERT).
  const updateInactive = content.matchAll(/UPDATE permissions\s+SET active = false[^;]*WHERE permission_name IN \(([^)]+)\)/gis);
  for (const m of updateInactive) {
    for (const nameMatch of m[1].matchAll(/'([a-z_][a-z0-9_]*:[a-z_][a-z0-9_]*)'/g)) {
      const name = nameMatch[1];
      active.delete(name);
      inactive.add(name);
    }
  }

  return { active, inactive };
}

function extractFromAdmin(content) {
  const found = new Set();
  for (const match of content.matchAll(/"([a-z_][a-z0-9_]*:[a-z_][a-z0-9_]*)"/g)) {
    found.add(match[1]);
  }
  for (const match of content.matchAll(/'([a-z_][a-z0-9_]*:[a-z_][a-z0-9_]*)'/g)) {
    found.add(match[1]);
  }
  return found;
}

function main() {
  const missing = [SEED_PATH, ADMIN_NAV_PATH, ADMIN_PERMS_PATH].filter((p) => !existsSync(p));
  if (missing.length) {
    console.log('SKIP — required sibling paths missing (repo not checked out alongside):');
    for (const p of missing) console.log(`  - ${p}`);
    process.exit(0);
  }

  const { active: seedActive, inactive: seedInactive } = extractFromSeed(readFileSync(SEED_PATH, 'utf8'));

  const adminUsed = new Set([
    ...extractFromAdmin(readFileSync(ADMIN_NAV_PATH, 'utf8')),
    ...extractFromAdmin(readFileSync(ADMIN_PERMS_PATH, 'utf8')),
  ]);

  const orphans = [];
  const inactiveRefs = [];
  for (const name of adminUsed) {
    if (ADMIN_VIRTUAL_ALLOWLIST.has(name)) continue;
    if (seedActive.has(name)) continue;
    if (seedInactive.has(name)) {
      inactiveRefs.push(name);
      continue;
    }
    orphans.push(name);
  }

  console.log('Permission consistency report');
  console.log('-----------------------------');
  console.log(`  seed permissions (active):   ${seedActive.size}`);
  console.log(`  seed permissions (inactive): ${seedInactive.size}`);
  console.log(`  admin references:            ${adminUsed.size}`);
  console.log(`  admin virtual (allowlisted): ${[...adminUsed].filter((n) => ADMIN_VIRTUAL_ALLOWLIST.has(n)).length}`);
  console.log(`  orphans (not in seed):       ${orphans.length}`);
  console.log(`  refs to inactive perms:      ${inactiveRefs.length}`);
  console.log('');

  if (inactiveRefs.length) {
    console.log('WARNING — admin references deprecated (inactive) permissions:');
    for (const name of inactiveRefs.sort()) console.log(`  - ${name}`);
    console.log('');
  }

  const strict = process.argv.includes('--strict');

  if (orphans.length) {
    const channel = strict ? console.error : console.warn;
    const label = strict ? 'FAIL' : 'WARNING';
    channel(`${label} — admin references permissions NOT present in seed:`);
    for (const name of orphans.sort()) channel(`  - ${name}`);
    channel('');
    channel('Fix: add the permission to sacdia-backend/prisma/seeds/permissions.seed.sql OR');
    channel('remove the reference from the admin (nav-config.ts / permissions.ts).');
    if (strict) process.exit(1);
    return;
  }

  console.log('OK — admin ↔ seed consistent.');
}

main();
