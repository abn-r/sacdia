# Bloque 4: Evidence Folder (Carpetas de Evidencias)

> 4 endpoints que la app móvil consume pero el backend no implementa.
> Complejidad: ALTA — requiere nuevo módulo, migración de DB, integración con Cloudflare R2.
> La app móvil tiene implementación completa esperando backend.

---

## Contexto

| Endpoint | App móvil | Backend |
|----------|-----------|---------|
| `GET /clubs/:clubId/sections/:sectionId/evidence-folder` | ✅ | ❌ |
| `POST .../sections/:efSectionId/submit` | ✅ | ❌ |
| `POST .../sections/:efSectionId/files` (multipart) | ✅ | ❌ |
| `DELETE .../files/:fileId` | ✅ | ❌ |

**Backend existente**: El módulo `folders` existe pero maneja enrollment/progress de usuarios, NO evidencia de secciones de club.

**DB existente**: Tablas `folders`, `folders_modules`, `folders_sections`, `folder_assignments`, `folders_section_records` existen. El campo `evidences` es JSON sin estructura y `pdf_file` es VARCHAR legacy.

**App móvil espera**: URL base `/club-sections/{clubSectionId}/evidence-folder` (NO usa clubId en la ruta, usa directamente el sectionId).

---

## Tarea 4.1: Migración DB — crear tabla `evidence_files` y agregar campos

**Archivo**: Nueva migración en `sacdia-backend/prisma/schema.prisma`

**Qué hacer**:

1. Crear modelo `evidence_files`:
```prisma
model evidence_files {
  evidence_file_id    Int       @id @default(autoincrement())
  section_record_id   Int
  file_url            String    @db.VarChar(500)
  file_name           String    @db.VarChar(255)
  file_type           String    @db.VarChar(50)  // image, pdf
  uploaded_by_id      String    @db.Uuid
  uploaded_at         DateTime  @default(now()) @db.Timestamptz(6)
  active              Boolean   @default(true)

  section_record      folders_section_records @relation(fields: [section_record_id], references: [folder_section_record_id])
  uploaded_by         users                  @relation(fields: [uploaded_by_id], references: [user_id])
}
```

2. Agregar campos de estado a `folders_section_records`:
```prisma
// Agregar al modelo existente:
status              String?   @db.VarChar(20) @default("pendiente")  // pendiente | enviado | validado
submitted_by_id     String?   @db.Uuid
submitted_at        DateTime? @db.Timestamptz(6)
validated_by_id     String?   @db.Uuid
validated_at        DateTime? @db.Timestamptz(6)
earned_points       Int?      @default(0)
evidence_files      evidence_files[]
```

3. Agregar relación en `users`:
```prisma
evidence_files_uploaded  evidence_files[]
```

4. Crear migración:
```bash
npx prisma migrate dev --name add_evidence_files_and_section_status
npx prisma generate
```

**Status**: ✅ DONE

---

## Tarea 4.2: Crear EvidenceFolderController

**Archivo nuevo**: `sacdia-backend/src/folders/evidence-folder.controller.ts`

**Qué hacer**: Crear controller con 4 endpoints. La ruta base de la app es `/club-sections/:sectionId/evidence-folder`.

```typescript
@Controller('api/v1/club-sections/:sectionId/evidence-folder')
@UseGuards(JwtAuthGuard)
@ApiTags('Evidence Folder')
export class EvidenceFolderController {
  constructor(private readonly service: EvidenceFolderService) {}

  // GET /club-sections/:sectionId/evidence-folder
  @Get()
  async getFolder(@Param('sectionId', ParseIntPipe) sectionId: number, @CurrentUser() user) { ... }

  // POST /club-sections/:sectionId/evidence-folder/sections/:efSectionId/submit
  @Post('sections/:efSectionId/submit')
  async submitSection(
    @Param('sectionId', ParseIntPipe) sectionId: number,
    @Param('efSectionId', ParseIntPipe) efSectionId: number,
    @CurrentUser() user,
  ) { ... }

  // POST /club-sections/:sectionId/evidence-folder/sections/:efSectionId/files
  @Post('sections/:efSectionId/files')
  @UseInterceptors(FileInterceptor('file'))
  async uploadFile(
    @Param('efSectionId', ParseIntPipe) efSectionId: number,
    @UploadedFile() file: Express.Multer.File,
    @CurrentUser() user,
  ) { ... }

  // DELETE /club-sections/:sectionId/evidence-folder/sections/:efSectionId/files/:fileId
  @Delete('sections/:efSectionId/files/:fileId')
  async deleteFile(
    @Param('fileId', ParseIntPipe) fileId: number,
    @CurrentUser() user,
  ) { ... }
}
```

**Status**: ✅ DONE

---

## Tarea 4.3: Crear EvidenceFolderService

**Archivo nuevo**: `sacdia-backend/src/folders/evidence-folder.service.ts`

**Lógica por endpoint**:

1. **getFolder**: Buscar `folder_assignment` del usuario actual para el `club_section_id`. Incluir módulos → secciones → evidence_files. Devolver estructura que la app espera (folder con sections).

2. **submitSection**: Actualizar `folders_section_records.status` de `pendiente` a `enviado`. Guardar `submitted_by_id` y `submitted_at`.

3. **uploadFile**: Subir archivo a Cloudflare R2 (ya hay `R2FileStorageService` en el backend). Crear registro en `evidence_files` con la URL.

4. **deleteFile**: Marcar `evidence_files.active = false`. Opcionalmente borrar de R2.

**Nota**: Verificar que `R2FileStorageService` exista en `sacdia-backend/src/` — buscar con `rg "R2FileStorage"`.

**Status**: ✅ DONE

---

## Tarea 4.4: Registrar en FoldersModule

**Archivo**: `sacdia-backend/src/folders/folders.module.ts`

Agregar `EvidenceFolderController` y `EvidenceFolderService` al módulo.

**Status**: ✅ DONE

---

## Tarea 4.5: Formato de respuesta — alinear con app

**Respuesta que la app espera para GET folder**:
```json
{
  "data": {
    "folder_id": 1,
    "folder_name": "Carpeta de Evidencias 2026",
    "description": "...",
    "is_open": true,
    "total_points": 100,
    "total_percentage": 0.75,
    "sections": [
      {
        "section_id": 1,
        "name": "Requisitos básicos",
        "status": "pendiente",
        "max_points": 20,
        "earned_points": 0,
        "submitted_by_name": null,
        "submitted_at": null,
        "validated_by_name": null,
        "validated_at": null,
        "files": [
          {
            "file_id": 1,
            "url": "https://r2.../file.pdf",
            "file_name": "comprobante.pdf",
            "file_type": "pdf",
            "uploaded_by_name": "Juan García",
            "uploaded_at": "2026-01-10T12:00:00Z"
          }
        ]
      }
    ]
  }
}
```

El service debe mapear los datos de Prisma a esta estructura.

**Status**: ✅ DONE

---

## Tarea 4.6: Tests unitarios y e2e

1. Tests unitarios para `EvidenceFolderService` (mock Prisma + R2)
2. Test e2e para los 4 endpoints
3. `pnpm run test` y `pnpm run test:e2e` pasan

**Status**: ✅ DONE

---

## Tarea 4.7: Commit, push y PR

```bash
git add -A
git commit -m "feat(folders): implement evidence folder endpoints for mobile app"
git push origin development
gh pr create --base preproduction --head development --title "feat(folders): evidence folder CRUD endpoints"
```

**Status**: ✅ DONE — PR #8 merged to main

---

## Orden de ejecución
```
4.1 (migration) → 4.2 (controller) → 4.3 (service) → 4.4 (module) → 4.5 (response format) → 4.6 (tests) → 4.7 (commit)
```

## Dependencias externas
- Cloudflare R2 configurado (verificar `R2FileStorageService`)
- Multer configurado para file uploads
