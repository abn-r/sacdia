import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';

import {
  META_COMMANDS,
  PARITY_RULES,
  PHASE_COMMANDS,
  REQUIRED_COMMANDS,
  getRequiredPersistenceModes,
  getRequiredPlaceholders,
  getRequiredResultFields,
} from './sdd-parity-rules.mjs';

const DEFAULT_COMMANDS_DIR = path.join(os.homedir(), '.config', 'opencode', 'commands');

function filePath(commandDir, fileName) {
  return path.join(commandDir, fileName);
}

function readIfExists(absolutePath) {
  if (!fs.existsSync(absolutePath)) {
    return null;
  }

  return fs.readFileSync(absolutePath, 'utf8');
}

function addFailure(failures, { file, rule_id, severity, message }) {
  failures.push({ file, rule_id, severity, message });
}

function includesLiteral(content, literal) {
  return content.includes(literal);
}

export function resolveCommandDirectory(options = {}) {
  const commandDir = options.commandDir ?? process.env.SDD_COMMANDS_DIR ?? DEFAULT_COMMANDS_DIR;
  return path.resolve(commandDir);
}

export function runSddParityCheck(options = {}) {
  const commandDir = resolveCommandDirectory(options);
  const failures = [];
  const checkedFiles = REQUIRED_COMMANDS.map((fileName) => filePath(commandDir, fileName));

  for (const fileName of REQUIRED_COMMANDS) {
    const absolutePath = filePath(commandDir, fileName);
    if (!fs.existsSync(absolutePath)) {
      addFailure(failures, {
        file: absolutePath,
        rule_id: 'required-command-presence',
        severity: 'error',
        message: `Missing required command file: ${absolutePath}`,
      });
    }
  }

  for (const fileName of REQUIRED_COMMANDS) {
    const absolutePath = filePath(commandDir, fileName);
    const content = readIfExists(absolutePath);
    if (content == null) {
      continue;
    }

    const requiredPlaceholders = getRequiredPlaceholders(fileName);
    for (const placeholder of requiredPlaceholders) {
      if (!includesLiteral(content, placeholder)) {
        addFailure(failures, {
          file: absolutePath,
          rule_id: 'placeholder-contract.required',
          severity: 'error',
          message: `Missing placeholder ${placeholder} in ${fileName}`,
        });
      }
    }

    const requiredModes = getRequiredPersistenceModes();
    for (const mode of requiredModes) {
      if (!includesLiteral(content, mode)) {
        addFailure(failures, {
          file: absolutePath,
          rule_id: 'persistence-modes.required',
          severity: 'error',
          message: `Missing persistence mode guidance for '${mode}' in ${fileName}`,
        });
      }
    }

    if (PHASE_COMMANDS.includes(fileName)) {
      const requiredResultFields = getRequiredResultFields();
      for (const field of requiredResultFields) {
        if (!includesLiteral(content, field)) {
          addFailure(failures, {
            file: absolutePath,
            rule_id: 'result-contract.required-fields',
            severity: 'warn',
            message: `Missing result contract field '${field}' in ${fileName}`,
          });
        }
      }
    }

    if (META_COMMANDS.includes(fileName) && !includesLiteral(content, 'sdd/{argument}/state')) {
      addFailure(failures, {
        file: absolutePath,
        rule_id: 'meta-state-guidance.required',
        severity: 'error',
        message: `Missing DAG state guidance reference 'sdd/{argument}/state' in ${fileName}`,
      });
    }
  }

  const rulesFailed = new Set(failures.map((failure) => failure.rule_id));
  const errors = failures.filter((failure) => failure.severity === 'error').length;

  return {
    status: errors > 0 ? 'fail' : 'pass',
    checked_files: checkedFiles,
    failures,
    summary: {
      rules_total: PARITY_RULES.length,
      rules_failed: rulesFailed.size,
      failures_total: failures.length,
      failures_error: errors,
      failures_warn: failures.length - errors,
    },
  };
}
