#!/usr/bin/env node

import path from 'node:path';

import { runSddParityCheck } from './lib/sdd-parity-runner.mjs';

function parseArgs(argv) {
  const args = { commandDir: undefined, json: false };

  for (let index = 0; index < argv.length; index += 1) {
    const value = argv[index];
    if (value === '--json') {
      args.json = true;
      continue;
    }

    if (value === '--command-dir') {
      const next = argv[index + 1];
      if (!next) {
        throw new Error('--command-dir requires a value');
      }
      args.commandDir = next;
      index += 1;
    }
  }

  return args;
}

function printHumanReport(report) {
  const statusLabel = report.status === 'pass' ? 'PASS' : 'FAIL';
  console.log(`SDD command parity check: ${statusLabel}`);
  console.log(`Checked files: ${report.checked_files.length}`);
  console.log(
    `Failures: ${report.summary.failures_total} (errors: ${report.summary.failures_error}, warnings: ${report.summary.failures_warn})`,
  );

  if (report.failures.length === 0) {
    console.log('No parity issues detected.');
    return;
  }

  console.log('Diagnostics:');
  for (const failure of report.failures) {
    const relative = path.relative(process.cwd(), failure.file) || failure.file;
    console.log(
      `- [${failure.severity.toUpperCase()}] ${failure.rule_id}: ${failure.message} (${relative})`,
    );
  }
}

try {
  const args = parseArgs(process.argv.slice(2));
  const report = runSddParityCheck({ commandDir: args.commandDir });

  if (args.json) {
    console.log(JSON.stringify(report, null, 2));
  } else {
    printHumanReport(report);
  }

  process.exit(report.status === 'pass' ? 0 : 1);
} catch (error) {
  const message = error instanceof Error ? error.message : String(error);
  console.error(`SDD parity check failed to run: ${message}`);
  process.exit(2);
}
