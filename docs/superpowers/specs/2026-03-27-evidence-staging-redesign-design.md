# Evidence Upload Staging Redesign — Design Spec

**Date**: 2026-03-27
**Status**: Draft
**Scope**: sacdia-app (Flutter) — RequirementDetailView + EvidenceSectionDetailView

## Problem

Evidence file uploads in both "clases progresivas" and "carpetas de evidencias" work file-by-file: pick one, upload immediately, repeat. There is no preview before upload, no way to batch-select and review before committing, and disabled buttons have poor visual styling (gray background with red border that looks broken). The same upload pattern is duplicated across two features with no shared code.

## Solution: Shared `EvidenceStagingManager` Widget

A reusable widget tree at `lib/core/widgets/evidence_staging/` that encapsulates the entire staging UX. Users add files locally, review them in a grid, then upload all at once when they submit for validation. Both classes (RequirementDetailView) and evidence folders (EvidenceSectionDetailView) consume this widget identically.

## Model: `StagedFile`

```dart
enum StagedFileStatus { uploaded, local, uploading, completed, error }

class StagedFile {
  final String id;              // UUID for remote files, generated locally for new ones
  final String name;            // file name
  final String type;            // 'image' | 'pdf'
  final StagedFileStatus status;
  final String? localPath;      // only for local files
  final String? remoteUrl;      // only for already-uploaded files
  final String? mimeType;
  final double uploadProgress;  // 0.0 - 1.0
  final String? errorMessage;
  final String? uploadedBy;     // uploader name
  final DateTime? uploadedAt;
}
```

Remote files enter with `status: uploaded`, new ones with `status: local`. On submit, locals transition: `local` → `uploading` → `completed` or `error`.

## File Structure

```
lib/core/widgets/evidence_staging/
├── evidence_staging_manager.dart    — main orchestrator widget
├── staged_file.dart                 — StagedFile model + enum
├── staged_file_grid.dart            — grid with unified display
├── upload_progress_sheet.dart       — bottom sheet with progress
└── image_source_dialog.dart         — shared camera/gallery picker dialog
```

## Widget Design

### `EvidenceStagingManager` (orchestrator)

The main widget consumed by both integration points.

```dart
EvidenceStagingManager({
  required List<StagedFile> existingFiles,  // already uploaded — caller maps domain entities to StagedFile(status: uploaded)
  required int maxFiles,
  required Future<void> Function(XFile file, String mimeType, void Function(double progress) onProgress) onUpload,  // single file upload callback with progress
  required Future<void> Function(String fileId) onDeleteRemote,  // delete already-uploaded file
  required Future<void> Function() onSubmit,  // mark as submitted for validation
  required String Function(String originalName, int index) fileNameBuilder,  // naming convention — index is the absolute position in the full file list (existing remote count + position in local batch), starting from 1
  required bool canModify,  // false when status != pendiente
})
```

> **I-1 — Decoupling note**: `ExistingFile` is not a shared type. Each feature maps its own domain entities to `StagedFile` before passing them in. `RequirementDetailView` maps `RequirementEvidence` → `StagedFile(status: uploaded)`, and `EvidenceSectionDetailView` maps `EvidenceFile` → `StagedFile(status: uploaded)`. `EvidenceStagingManager` only knows about `StagedFile`.

> **I-2 — Upload progress note**: The `onUpload` callback receives an `onProgress` callback that maps directly to Dio's `onSendProgress`. The `EvidenceStagingManager` passes a closure that calls `setState` to update the corresponding `StagedFile.uploadProgress` in the internal staging list as bytes are transferred.

**Internal state**: `List<StagedFile>` combining existing remote files + locally staged files. Managed with `StatefulWidget` + `setState` — no Riverpod notifier needed since this state is local to the widget tree and does not need to be shared across the app.

> **S-3 — State management note**: `EvidenceStagingManager` is a `StatefulWidget`. All staging list mutations (add, remove, status transitions, progress updates) go through `setState`. Riverpod is used only for the notifiers in the parent screens (`RequirementNotifier`, `EvidenceSectionNotifier`), not inside the staging widget itself.

**Manages**:
- Multi-select image picker (gallery) and single camera capture
- Multi-select PDF picker
- Local staging list
- Limit validation (total files vs maxFiles)
- Upload queue execution (sequential, one at a time)
- Progress tracking per file
- Error handling with retry
- Disabled state when `canModify` is false

### `StagedFileGrid`

3-column grid, aspect ratio 0.82 (matches existing grid). Each tile renders differently based on status:

| Status | Appearance |
|--------|------------|
| `uploaded` | Thumbnail or PDF icon + green check badge (top-right) + uploader name + date (bottom) |
| `local` | Thumbnail or PDF icon + dashed green border + "Nuevo" badge (top-right, green) + red X button (top-left) to remove from staging |
| Excess over limit | Same as `local` but with red border instead of green |

> **S-1 — Delete behavior**: Local files (`status: local`) are removed immediately from the staging list when the red X is tapped — no confirmation needed since nothing has been sent to the server. Remote files (`status: uploaded`) show a confirmation dialog before calling `onDeleteRemote`, because deletion is a destructive API call that cannot be undone.

Below the grid: file counter `"X de Y archivos"`. If total exceeds maxFiles: red text `"Tenés Z archivos de más, eliminá algunos para continuar"`.

### Bottom Action Bar

Three buttons at the bottom (same position as current):

| Button | Style | Action |
|--------|-------|--------|
| Imagen | outline | Opens image source dialog (Camera single / Gallery multi-select) |
| PDF | outline | Opens file picker with `allowMultiple: true` |
| Enviar a validación | primary | Confirmation dialog → triggers upload queue → submit |

"Enviar a validación" is disabled when: no new local files AND no changes, OR total files > maxFiles.

All buttons disabled when `canModify` is false or upload is in progress.

### `UploadProgressSheet`

Persistent bottom sheet (`isDismissible: false`, `enableDrag: false`). Appears when user confirms upload.

**Header**: "Subiendo 3 de 7 archivos..." + linear progress bar (overall progress).

**File list**: Each file shows:
- File icon (image/PDF)
- File name
- Status indicator:

| Status | Indicator |
|--------|-----------|
| Pending | Yellow dot |
| Uploading | Blue dot + percentage text |
| Completed | Green check |
| Error | Red X + "Reintentar" button |

**On all complete (no errors)**: Header changes to "Todos los archivos subidos" (green). Shows "Continuar" button that closes the sheet and triggers the submit-for-validation call.

**On complete with errors**: Header shows "X de Y subidos, Z fallaron" (orange). Three buttons:
- **"Reintentar fallidos"** — re-queues failed files and restarts the upload queue for them
- **"Continuar con los subidos"** — proceeds with uploaded files only and marks as submitted; shows a warning before confirming: "Los Z archivos que fallaron no se incluirán en la validación."
- **"Cancelar"** — closes the sheet and keeps all staging intact; already-uploaded files remain on the server, failed files return to `local` status in the staging list so the user can review, modify, or retry later

> **I-3 — Partial failure note**: The three-option design avoids forcing the user to either retry everything or lose control. "Cancelar" is a safe exit — it does not discard what was already uploaded, nor does it submit incomplete data.

### `ImageSourceDialog`

Shared dialog offering Camera (single capture) or Gallery (multi-select). Replaces duplicated picker logic in both views.

## Disabled Button UX Improvement

Applied globally in `SacButton` (affects all buttons across the app):

| Property | Current (broken) | New |
|----------|-------------------|-----|
| Background | Gray | `surface` (very light) |
| Border | Red/theme color | `border` color (neutral) |
| Text/Icon | Theme color remnant | `textTertiary` (muted) |
| Transition | None | Animated 200ms |

No theme color remnant when disabled. The disabled state must look intentionally inactive, not visually broken.

> **I-4 — SacButton structural change**: The current `SacButton` implementation resolves disabled colors using static `AppColors` constants and `WidgetStateProperty` (resolved outside the `build` method). Fixing the disabled style is not just a color swap — it requires refactoring the disabled state resolution to read from `context.sac` (the `SacColors` extension) inside the `build` method, where `BuildContext` is available. This is a structural change to how `SacButton` resolves its color scheme.

## Integration Points

### Classes — `RequirementDetailView`

Replace:
- `_pickImage()`, `_pickPdf()`, `_isUploading` state, inline grid, bottom action bar

With:
- `EvidenceStagingManager` widget with callbacks to `RequirementNotifier.uploadFile()` and `RequirementNotifier.submit()`

### Evidence Folders — `EvidenceSectionDetailView`

Same replacement pattern using `EvidenceSectionNotifier.uploadFile()` and `EvidenceSectionNotifier.submit()`.

### `PopScope` — Back Navigation Guard

Both `RequirementDetailView` and `EvidenceSectionDetailView` must wrap their content in a `PopScope` widget with `canPop: false` when there are staged local files (i.e., `StagedFile` entries with `status: local` in the staging list). On back attempt, show a confirmation dialog: "Tenés archivos sin enviar. ¿Seguro que querés salir?" and only call `Navigator.pop` if the user confirms.

### Provider Invalidation Timing

Provider invalidation (to refresh the grid with newly confirmed remote files) must happen **after the entire batch completes**, not after each individual file upload. Invalidating mid-batch would trigger unnecessary rebuilds and could cause state inconsistencies while the upload queue is still running.

## Edge Cases

| Scenario | Behavior |
|----------|----------|
| User navigates away with local files staged | Show confirmation dialog: "Tenés archivos sin enviar. ¿Seguro que querés salir?" |
| App killed during upload | Files in staging are lost (acceptable — they're local temp files). Already-uploaded files are safe on server. |
| Zero new files but existing files | "Enviar a validación" still works — skips upload phase, goes straight to submit |
| All files remote, user just wants to submit | Skip upload phase entirely, go straight to submit call |
| Total files exceed maxFiles | Red border on excess tiles, red warning text below grid, "Enviar a validación" disabled |

## Backend Impact

**None.** All uploads remain single-file POST requests. The staging is purely client-side. Files are uploaded sequentially during the batch submit. Backend endpoints are unchanged.

## Dependencies

No new dependencies required. `ImagePicker` and `FilePicker` already support multi-select in the current project setup.

## Deprecations

Once integration is complete, the following files must be deleted:

- `evidence_file_grid.dart` — replaced by `StagedFileGrid`
- `requirement_evidence_grid.dart` — replaced by `StagedFileGrid`

Both grids served a single-feature purpose. `StagedFileGrid` is the unified replacement for both.

## Scope Summary

- **In scope**: `EvidenceStagingManager` widget tree, `SacButton` disabled style fix, integration in RequirementDetailView and EvidenceSectionDetailView, deletion of deprecated grid widgets
- **Out of scope**: Backend changes, new API endpoints, new package dependencies
