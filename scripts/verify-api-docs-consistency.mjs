#!/usr/bin/env node

import fs from 'node:fs';
import path from 'node:path';

const DOCS_API_DIR = path.join(process.cwd(), 'docs', '02-API');
const CANONICAL_FILE = 'ENDPOINTS-LIVE-REFERENCE.md';
const COMPAT_ALIAS_FILES = ['API-REFERENCE.md', 'COMPLETE-API-REFERENCE.md'];

const errors = [];

function readDoc(fileName) {
  const fullPath = path.join(DOCS_API_DIR, fileName);
  if (!fs.existsSync(fullPath)) {
    errors.push(`Missing file: docs/02-API/${fileName}`);
    return '';
  }

  return fs.readFileSync(fullPath, 'utf8');
}

function countEndpointEntries(markdown) {
  const tableRows =
    markdown.match(/^\|\s*(GET|POST|PUT|PATCH|DELETE)\s*\|\s*`?\/api\/v\d+/gm) ?? [];
  const bulletRows =
    markdown.match(/^-\s*`(GET|POST|PUT|PATCH|DELETE)\s+\/api\/v\d+/gm) ?? [];

  return tableRows.length + bulletRows.length;
}

const canonicalContent = readDoc(CANONICAL_FILE);
const canonicalCount = countEndpointEntries(canonicalContent);

if (canonicalContent && canonicalCount < 100) {
  errors.push(
    `Canonical file docs/02-API/${CANONICAL_FILE} looks incomplete: detected ${canonicalCount} endpoint entries.`,
  );
}

for (const aliasFile of COMPAT_ALIAS_FILES) {
  const aliasContent = readDoc(aliasFile);
  if (!aliasContent) {
    continue;
  }

  if (!aliasContent.includes('<!-- CANONICAL-REDIRECT -->')) {
    errors.push(
      `docs/02-API/${aliasFile} must include <!-- CANONICAL-REDIRECT --> marker.`,
    );
  }

  if (!aliasContent.includes('ENDPOINTS-LIVE-REFERENCE.md')) {
    errors.push(`docs/02-API/${aliasFile} must link to ENDPOINTS-LIVE-REFERENCE.md.`);
  }

  const aliasEndpointCount = countEndpointEntries(aliasContent);
  if (aliasEndpointCount > 0) {
    errors.push(
      `docs/02-API/${aliasFile} reintroduces duplicated runtime inventory (${aliasEndpointCount} endpoint entries found).`,
    );
  }
}

for (const indexPath of ['docs/README.md', 'docs/02-API/README.md']) {
  const absolute = path.join(process.cwd(), indexPath);
  if (!fs.existsSync(absolute)) {
    errors.push(`Missing index file: ${indexPath}`);
    continue;
  }

  const content = fs.readFileSync(absolute, 'utf8');
  if (!content.includes('ENDPOINTS-LIVE-REFERENCE.md')) {
    errors.push(`${indexPath} must reference ENDPOINTS-LIVE-REFERENCE.md as canonical.`);
  }
}

if (errors.length > 0) {
  console.error('API docs consistency check failed:\n');
  for (const error of errors) {
    console.error(`- ${error}`);
  }
  process.exit(1);
}

console.log(
  `API docs consistency check passed. Canonical endpoints detected: ${canonicalCount}.`,
);
