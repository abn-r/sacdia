export const REQUIRED_COMMANDS = [
  'sdd-init.md',
  'sdd-explore.md',
  'sdd-propose.md',
  'sdd-spec.md',
  'sdd-design.md',
  'sdd-tasks.md',
  'sdd-apply.md',
  'sdd-verify.md',
  'sdd-archive.md',
  'sdd-new.md',
  'sdd-continue.md',
  'sdd-ff.md',
];

export const PHASE_COMMANDS = [
  'sdd-init.md',
  'sdd-explore.md',
  'sdd-propose.md',
  'sdd-spec.md',
  'sdd-design.md',
  'sdd-tasks.md',
  'sdd-apply.md',
  'sdd-verify.md',
  'sdd-archive.md',
];

export const META_COMMANDS = ['sdd-new.md', 'sdd-continue.md', 'sdd-ff.md'];

export const PLACEHOLDER_REQUIREMENTS = {
  'sdd-init.md': ['{workdir}', '{project}'],
  'sdd-explore.md': ['{workdir}', '{project}', '{argument}'],
  'sdd-propose.md': ['{workdir}', '{project}', '{argument}'],
  'sdd-spec.md': ['{workdir}', '{project}', '{argument}'],
  'sdd-design.md': ['{workdir}', '{project}', '{argument}'],
  'sdd-tasks.md': ['{workdir}', '{project}', '{argument}'],
  'sdd-apply.md': ['{workdir}', '{project}'],
  'sdd-verify.md': ['{workdir}', '{project}'],
  'sdd-archive.md': ['{workdir}', '{project}'],
  'sdd-new.md': ['{workdir}', '{project}', '{argument}'],
  'sdd-continue.md': ['{workdir}', '{project}', '{argument}'],
  'sdd-ff.md': ['{workdir}', '{project}', '{argument}'],
};

const PERSISTENCE_MODES = ['engram', 'openspec', 'hybrid', 'none'];
const RESULT_FIELDS = ['status', 'executive_summary', 'artifacts', 'next_recommended'];

export const PARITY_RULES = [
  {
    rule_id: 'required-command-presence',
    scope: 'global',
    severity: 'error',
    description: 'All required SDD command files must exist.',
  },
  {
    rule_id: 'placeholder-contract.required',
    scope: 'file',
    severity: 'error',
    description: 'Required placeholders must exist for each command.',
  },
  {
    rule_id: 'persistence-modes.required',
    scope: 'file',
    severity: 'error',
    description:
      'Mode-aware persistence guidance must mention engram, openspec, hybrid, and none.',
  },
  {
    rule_id: 'result-contract.required-fields',
    scope: 'file',
    severity: 'warn',
    description: 'Phase command output contract must include required result fields.',
  },
  {
    rule_id: 'meta-state-guidance.required',
    scope: 'file',
    severity: 'error',
    description: 'Meta commands must reference sdd/{argument}/state guidance.',
  },
];

export function getRequiredPlaceholders(fileName) {
  return PLACEHOLDER_REQUIREMENTS[fileName] ?? [];
}

export function getRequiredPersistenceModes() {
  return [...PERSISTENCE_MODES];
}

export function getRequiredResultFields() {
  return [...RESULT_FIELDS];
}
