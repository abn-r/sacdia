#!/usr/bin/env node

const mode = process.argv[2];
const short = process.argv.includes('--short');

const presets = {
  gentleman: {
    short: `Modo \`gentleman\` para SACDIA:
- lee \`AGENTS.md\`, \`README.md\`, \`docs/README.md\` y \`docs/00-STEERING/*\`
- resolve tareas chicas con minimo cambio correcto
- valida contratos antes de tocar codigo
- si cambia comportamiento, sincroniza docs
- verifica antes de afirmar que quedo arreglado
- si aparecen 2+ archivos o riesgo medio, escala a \`sdd-lite\``,
    full: `Actua como "Gentleman" para SACDIA.

Objetivo:
- resolver tareas chicas con criterio senior, sin burocracia innecesaria
- mantener foco en claridad, verificacion y minimo cambio correcto

Reglas:
- lee primero \`AGENTS.md\`, \`README.md\`, \`docs/README.md\` y \`docs/00-STEERING/*\`
- no asumas contratos; validalos en docs o codigo
- si el cambio afecta comportamiento, sincroniza docs en el mismo trabajo
- no escales complejidad sin motivo; cambia solo lo necesario
- verifica antes de afirmar que algo esta arreglado
- si durante la exploracion aparecen multiples archivos, cambio de contrato o riesgo medio, escala a \`sdd-lite\`

Salida esperada:
- explica problema, cambio aplicado, verificacion realizada y docs tocadas`,
  },
  'sdd-lite': {
    short: `Modo \`sdd-lite\` para SACDIA:
- lee \`AGENTS.md\`, \`README.md\`, \`docs/README.md\` y \`docs/00-STEERING/*\`
- antes de implementar, crea un micro artefacto con \`docs/templates/codex-small-task.md.template\`
- si afecta negocio, guardalo en \`docs/01-FEATURES/<feature>/changes/YYYY-MM-DD-<slug>.md\`
- define alcance, fuera de alcance, archivos impactados, verificacion y docs a sincronizar
- si el cambio crece, escala a SDD completo`,
    full: `Actua como "SDD Lite Orchestrator" para SACDIA.

Objetivo:
- manejar tareas chicas o medianas con trazabilidad minima sin invocar el flujo SDD completo

Reglas:
- lee primero \`AGENTS.md\`, \`README.md\`, \`docs/README.md\` y \`docs/00-STEERING/*\`
- antes de tocar codigo, crea un micro artefacto usando \`docs/templates/codex-small-task.md.template\`
- si el cambio afecta negocio, guarda el artefacto en \`docs/01-FEATURES/<feature>/changes/YYYY-MM-DD-<slug>.md\`
- define alcance, fuera de alcance, archivos impactados, verificacion y docs a sincronizar
- implementa solo despues de escribir ese micro plan
- si el cambio crece, escala a \`requirements.md\` + \`design.md\` + \`tasks.md\`

Salida esperada:
- micro artefacto creado, implementacion ejecutada, verificacion hecha, docs sincronizadas`,
  },
};

function printUsage() {
  console.error(`Uso: node scripts/codex-preset.mjs <gentleman|sdd-lite> [--short]`);
}

if (!mode || !presets[mode]) {
  printUsage();
  process.exit(1);
}

process.stdout.write(`${short ? presets[mode].short : presets[mode].full}\n`);
