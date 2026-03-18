---
title: Clases Progresivas
status: implemented
priority: high
---

# Clases Progresivas

## Descripción

Sistema para gestionar las clases progresivas de cada tipo de club, incluyendo inscripciones de usuarios y seguimiento de progreso por módulos y secciones.

## Clases por Tipo

### Aventureros (6-9 años)

- Abejita Industriosa
- Rayito de Sol
- Constructor
- Manos Ayudadoras

### Conquistadores (10-15 años)

- Amigo
- Compañero
- Explorador
- Orientador
- Viajero
- Guía

### Guías Mayores (16+ años)

- Guía Mayor
- Guía Mayor Avanzado
- Guía Mayor Máster

## Estructura de Clases

```
Clase
├── Módulo 1
│   ├── Sección 1.1
│   ├── Sección 1.2
│   └── ...
├── Módulo 2
│   ├── Sección 2.1
│   └── ...
└── ...
```

## Requisitos Implementados

### 1. Catálogo de Clases

- [x] Listado de clases por tipo de club
- [x] Detalle de clase con módulos y secciones
- [x] Edad mínima requerida
- [x] Material de estudio (URL)

### 2. Inscripciones

- [x] Inscripción de usuario a clase
- [x] Vinculación a año eclesiástico
- [x] Prevención de inscripciones duplicadas
- [x] Histórico de inscripciones

### 3. Seguimiento de Progreso

- [x] Puntaje por sección (0-100)
- [x] Evidencias adjuntas (JSON flexible)
- [x] Cálculo de progreso por módulo
- [x] Cálculo de progreso general
- [x] Umbral de aprobación: 70%

## Endpoints

```
# Catálogo (público)
GET /classes                      # Listar clases (paginado)
GET /classes/:classId             # Detalle de clase
GET /classes/:classId/modules     # Módulos de la clase

# Usuario (autenticado)
GET   /users/:userId/classes                     # Inscripciones
POST  /users/:userId/classes/enroll              # Inscribir
GET   /users/:userId/classes/:classId/progress   # Progreso
PATCH /users/:userId/classes/:classId/progress   # Actualizar
```

## Respuesta de Progreso

```json
{
  "class_id": 1,
  "class_name": "Amigo",
  "total_sections": 25,
  "completed_sections": 10,
  "overall_progress": 40,
  "modules": [
    {
      "module_id": 1,
      "module_name": "Desarrollo Personal",
      "total_sections": 5,
      "completed_sections": 3,
      "progress_percentage": 60,
      "sections": [
        {
          "section_id": 1,
          "section_name": "Requisito Básico",
          "completed": true,
          "score": 85,
          "evidences": null
        }
      ]
    }
  ]
}
```

## Archivos Clave

- `src/classes/classes.module.ts`
- `src/classes/classes.controller.ts`
- `src/classes/classes.service.ts`
- `src/classes/dto/classes.dto.ts`

## Dependencias

- `PrismaModule`
- `JwtAuthGuard` (para endpoints de usuario)

---

**Implementado**: 2026-01-31
**Estado**: ✅ Completado
