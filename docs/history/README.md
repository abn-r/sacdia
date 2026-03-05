# Historial de Documentación SACDIA

Esta carpeta contiene documentación **histórica, de auditoría o de trabajo intermedio**.

## Objetivo

Separar la documentación operativa (canónica) de la documentación de contexto histórico para reducir ruido y evitar conflictos de fuente de verdad.

## Convención de Estado

- `ACTIVE`: documento canónico y vigente.
- `HISTORICAL`: bitácora, sesión, plan cerrado o auditoría de fecha puntual.
- `DEPRECATED`: documento sustituido por otro canónico.

## Estructura

- `navigation/`: índices antiguos y documentos de estructura anteriores.
- `guides/`: versiones previas de guías consolidadas.
- `api/`: auditorías y documentos API históricos.
- `source/`: insumos de consolidación (`_source_docs`) movidos fuera de la capa canónica.
- `database/`: artefactos de respaldo de documentación DB.
- `phases/`: planes y reportes históricos de fases.
- `plans/`: planes detallados reemplazados por versiones consolidadas.
- `implementation/`: sesiones de implementación y cierres históricos.
- `feature-context/`: `CLAUDE.md` per-feature históricos.
- `changelog/`: bitácoras históricas consolidadas.

## Regla de Uso

No usar `docs/history/` como contrato operativo para implementación nueva.

