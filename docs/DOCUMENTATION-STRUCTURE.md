# 📚 Estructura de Documentación - SACDIA

**Última actualización**: 2026-01-30

---

## 📁 Estructura Actual

```
docs/
├── README.md                              ⭐ INICIO AQUÍ - Punto de entrada
├── 01-OVERVIEW.md                         📖 Visión general del proyecto
├── 02-PROCESSES.md                        🔄 Procesos de negocio
├── 03-IMPLEMENTATION-ROADMAP.md           🗺️ Roadmap de implementación
├── _archive/                              📦 (Para archivos obsoletos futuros)
│
├── database/                              🗄️ Base de Datos
│   ├── README.md                          📖 Guía de BD y Prisma
│   ├── SCHEMA-REFERENCE.md                📋 Referencia completa (consolidado)
│   ├── schema.prisma                      ⚙️ Schema Prisma oficial
│   ├── schema.prisma.backup_*             💾 Backup del schema
│   ├── schema_additions_phase1.prisma     📝 Adiciones fase 1
│   ├── migration-schema-v2.sql            🔄 Migración v2
│   ├── migrations/                        📂 Scripts SQL
│   │   ├── README.md                      📖 Guía de migraciones
│   │   ├── script_01_organizacion.sql
│   │   ├── script_02_clubes_clases.sql
│   │   ├── script_03_especialidades.sql
│   │   ├── script_04_catalogos_medicos.sql
│   │   ├── script_05_roles_permisos.sql
│   │   └── ... (11 archivos SQL)
│   ├── examples/
│   │   └── sample_responses.json
│   └── _source_docs/                      📦 Documentos originales
│       ├── relations.md
│       ├── auditoria-naming-bd.md
│       ├── verificacion-schema-prisma.md
│       └── migration_phase1_guide.md
│
└── api/                                   🌐 REST API
    ├── README.md                          📖 Guía de API
    ├── API-SPECIFICATION.md               📋 Especificación técnica v2.0
    ├── ENDPOINTS-REFERENCE.md             🔗 Referencia de endpoints
    ├── ARCHITECTURE-DECISIONS.md          🏛️ Decisiones arquitectónicas (ADRs)
    ├── walkthrough-backend-init.md        🚀 Walkthrough del backend
    └── _source_docs/                      📦 Documentos originales
        ├── analisis-completo-api.md
        ├── analisis-club-members-vs-roles.md
        ├── analisis-consistencia-documentacion.md
        ├── decisiones-estandarizacion.md
        ├── especificacion-tecnica-nueva-api.md
        ├── informe-seguridad-mejoras.md
        ├── mapeo-procesos-endpoints.md
        ├── plan-actualizacion-documentos.md
        ├── queries-club-role-assignments.md
        ├── reestructuracion-endpoints-versionado.md
        └── restrucura-roles.md
```

---

## 🎯 Guía de Navegación por Rol

### Backend Developer
```
1. README.md → 01-OVERVIEW.md
2. database/README.md → database/SCHEMA-REFERENCE.md
3. api/README.md → api/API-SPECIFICATION.md
4. 03-IMPLEMENTATION-ROADMAP.md
```

### Mobile Developer
```
1. README.md → 01-OVERVIEW.md
2. 02-PROCESSES.md (flujos de usuario)
3. api/ENDPOINTS-REFERENCE.md
4. api/API-SPECIFICATION.md
```

### Frontend/Admin Developer
```
1. README.md → 01-OVERVIEW.md
2. api/API-SPECIFICATION.md
3. api/ARCHITECTURE-DECISIONS.md (RBAC)
```

---

## 📊 Estadísticas

### Archivos Principales (visibles)
- **Raíz**: 4 archivos (README + 3 docs principales)
- **Database**: 7 archivos + 12 SQL scripts
- **API**: 5 archivos
- **Total**: ~16 archivos principales

### Archivos Fuente (archivados)
- **database/_source_docs**: 4 archivos
- **api/_source_docs**: 11 archivos
- **Total**: 15 archivos de referencia

---

## ✅ Validación de Links

Todos los links cruzados han sido verificados:

- ✅ Links relativos funcionan correctamente
- ✅ Referencias entre carpetas (`../`) funcionan
- ✅ No hay links rotos a archivos renombrados
- ✅ Archivos originales preservados en `_source_docs/`

---

## 🔄 Cambios Aplicados

### Renombrados
- `procesos-sacdia.md` → `02-PROCESSES.md`
- `roadmap-implementacion.md` → `03-IMPLEMENTATION-ROADMAP.md`

### Reorganizados
- `restapi/` → `api/`
- `database/backups/` → `database/migrations/`

### Consolidados
- Database: `relations.md` + `auditoria-naming-bd.md` + `verificacion-schema-prisma.md` → `SCHEMA-REFERENCE.md`
- API: Múltiples docs → `API-SPECIFICATION.md`, `ENDPOINTS-REFERENCE.md`, `ARCHITECTURE-DECISIONS.md`

---

## 📌 Documentos Clave

| Categoría | Documento | Propósito |
|-----------|-----------|-----------|
| **Inicio** | `README.md` | Punto de entrada único |
| **Overview** | `01-OVERVIEW.md` | Arquitectura y stack |
| **Base de Datos** | `database/SCHEMA-REFERENCE.md` | Referencia completa del schema |
| **API** | `api/API-SPECIFICATION.md` | Especificación técnica de la API |
| **Procesos** | `02-PROCESSES.md` | Flujos de negocio |
| **Roadmap** | `03-IMPLEMENTATION-ROADMAP.md` | Plan de implementación |

---

## 🔍 Búsqueda Rápida

**¿Buscas...?**

- **Schema de BD**: `database/schema.prisma` o `database/SCHEMA-REFERENCE.md`
- **Endpoints de API**: `api/ENDPOINTS-REFERENCE.md`
- **Migraciones SQL**: `database/migrations/README.md`
- **Decisiones técnicas**: `api/ARCHITECTURE-DECISIONS.md`
- **Flujos de usuario**: `02-PROCESSES.md`
- **Sistema RBAC**: `api/ARCHITECTURE-DECISIONS.md` (ADR-002)

---

## 🛠️ Mantenimiento

### Para actualizar documentación:
1. Edita el archivo principal (no los `_source_docs`)
2. Actualiza links si renombras archivos
3. Mantén `README.md` sincronizado

### Para agregar nueva documentación:
- Docs técnicos → Carpeta apropiada (`database/` o `api/`)
- Docs generales → Raíz con prefijo numérico si es secuencial
- Actualiza `README.md` con el nuevo documento

---

**Mantenido por**: Equipo SACDIA  
**Versión de docs**: 2.0 (Consolidada)
