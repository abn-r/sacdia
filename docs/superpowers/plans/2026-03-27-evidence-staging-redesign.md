# Evidence Upload Staging Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace immediate file-by-file uploads with a local staging area where users preview, add/remove files, then batch-upload on submission — shared across classes and evidence folders.

**Architecture:** Shared widget tree at `lib/core/widgets/evidence_staging/` consumed by both `RequirementDetailView` (classes) and `EvidenceSectionDetailView` (evidence folders). `EvidenceStagingManager` is a `StatefulWidget` that owns the staging list via `setState` — no Riverpod needed for internal state. Each integration point maps its own domain entities (`RequirementEvidence` / `EvidenceFile`) to a unified `StagedFile` model before passing them in. Uploads remain single-file POST requests executed sequentially during batch submit. Backend is unchanged.

**Tech Stack:** Flutter 3.x, Riverpod, Dio, ImagePicker, FilePicker

**Spec:** `docs/superpowers/specs/2026-03-27-evidence-staging-redesign-design.md`

---

## File Structure

| Action | File | Responsibility |
|--------|------|----------------|
| Create | `lib/core/widgets/evidence_staging/staged_file.dart` | `StagedFile` model + `StagedFileStatus` enum + factory helpers |
| Create | `lib/core/widgets/evidence_staging/image_source_dialog.dart` | Shared camera/gallery picker bottom sheet |
| Create | `lib/core/widgets/evidence_staging/staged_file_grid.dart` | Unified grid showing remote + local files |
| Create | `lib/core/widgets/evidence_staging/upload_progress_sheet.dart` | Persistent bottom sheet with per-file upload progress |
| Modify | `lib/features/classes/data/datasources/classes_remote_data_source.dart` | Wire `onProgress` callback to Dio `onSendProgress` |
| Modify | `lib/features/classes/data/repositories/classes_repository_impl.dart` | Pass through `onProgress` callback |
| Modify | `lib/features/classes/domain/repositories/classes_repository.dart` | Add `onProgress` to abstract interface |
| Modify | `lib/features/classes/domain/usecases/upload_requirement_file.dart` | Add `onProgress` to params |
| Modify | `lib/features/classes/presentation/providers/classes_providers.dart` | Add `onProgress` + `skipInvalidation` to `RequirementNotifier.uploadFile()` |
| Modify | `lib/features/evidence_folder/data/datasources/evidence_folder_remote_data_source.dart` | Wire `onProgress` callback to Dio `onSendProgress` |
| Modify | `lib/features/evidence_folder/data/repositories/evidence_folder_repository_impl.dart` | Pass through `onProgress` callback |
| Modify | `lib/features/evidence_folder/domain/repositories/evidence_folder_repository.dart` | Add `onProgress` to abstract interface |
| Modify | `lib/features/evidence_folder/domain/usecases/upload_evidence_file.dart` | Add `onProgress` to params |
| Modify | `lib/features/evidence_folder/presentation/providers/evidence_folder_providers.dart` | Add `onProgress` + `skipInvalidation` to `EvidenceSectionNotifier.uploadFile()` |
| Create | `lib/core/widgets/evidence_staging/evidence_staging_manager.dart` | Main orchestrator widget with built-in action bar |
| Modify | `lib/core/widgets/sac_button.dart` | Fix disabled state to use `context.sac` theme tokens, remove AnimatedOpacity no-op |
| Modify | `lib/features/classes/presentation/views/requirement_detail_view.dart` | Replace picker/grid/bar with `EvidenceStagingManager` |
| Modify | `lib/features/evidence_folder/presentation/views/evidence_section_detail_view.dart` | Replace picker/grid/bar with `EvidenceStagingManager` |
| Delete | `lib/features/classes/presentation/widgets/requirement_evidence_grid.dart` | Replaced by `StagedFileGrid` |
| Delete | `lib/features/evidence_folder/presentation/widgets/evidence_file_grid.dart` | Replaced by `StagedFileGrid` |

---

## Task 1: StagedFile Model

**Files:**
- Create: `lib/core/widgets/evidence_staging/staged_file.dart`

- [ ] **Step 1: Create the `staged_file.dart` file with the `StagedFileStatus` enum, `StagedFile` model class, and factory helpers for mapping from both domain entities**

```dart
import 'package:equatable/equatable.dart';

import '../../../features/classes/domain/entities/requirement_evidence.dart'
    as classes;
import '../../../features/evidence_folder/domain/entities/evidence_file.dart'
    as evidence;

/// Status of a file within the staging area.
enum StagedFileStatus {
  /// Already uploaded and confirmed on the server.
  uploaded,

  /// Picked locally, not yet sent.
  local,

  /// Currently being uploaded.
  uploading,

  /// Upload finished successfully.
  completed,

  /// Upload failed.
  error,
}

/// Unified file model for the evidence staging area.
///
/// Both `RequirementEvidence` (classes) and `EvidenceFile` (evidence folders)
/// are mapped to this model before being passed to `EvidenceStagingManager`.
/// Local files (picked but not uploaded) use [status] = [StagedFileStatus.local].
class StagedFile extends Equatable {
  /// UUID for remote files, generated locally (milliseconds timestamp) for new ones.
  final String id;

  /// Display name of the file.
  final String name;

  /// `'image'` or `'pdf'`.
  final String type;

  final StagedFileStatus status;

  /// Local filesystem path — only present for locally staged files.
  final String? localPath;

  /// Remote URL (signed) — only present for already-uploaded files.
  final String? remoteUrl;

  /// MIME type (e.g. `'image/jpeg'`, `'application/pdf'`).
  final String? mimeType;

  /// Upload progress from 0.0 to 1.0.
  final double uploadProgress;

  /// Error message if upload failed.
  final String? errorMessage;

  /// Name of the person who uploaded the file (remote files only).
  final String? uploadedBy;

  /// Timestamp of when the file was uploaded (remote files only).
  final DateTime? uploadedAt;

  const StagedFile({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    this.localPath,
    this.remoteUrl,
    this.mimeType,
    this.uploadProgress = 0.0,
    this.errorMessage,
    this.uploadedBy,
    this.uploadedAt,
  });

  // ── Computed helpers ──────────────────────────────────────────────────────

  bool get isImage => type == 'image';
  bool get isPdf => type == 'pdf';
  bool get isLocal => status == StagedFileStatus.local;
  bool get isRemote => status == StagedFileStatus.uploaded;

  // ── copyWith ──────────────────────────────────────────────────────────────

  /// Sentinel object used to distinguish "not provided" from "set to null"
  /// for nullable fields in [copyWith].
  static const _sentinel = Object();

  /// Creates a copy with the given fields replaced.
  ///
  /// Nullable fields ([errorMessage], [localPath], [remoteUrl], [mimeType],
  /// [uploadedBy], [uploadedAt]) use a sentinel pattern so they can be
  /// explicitly cleared by passing `null`:
  /// ```dart
  /// file.copyWith(errorMessage: null) // clears errorMessage
  /// file.copyWith()                   // keeps existing errorMessage
  /// ```
  StagedFile copyWith({
    String? id,
    String? name,
    String? type,
    StagedFileStatus? status,
    Object? localPath = _sentinel,
    Object? remoteUrl = _sentinel,
    Object? mimeType = _sentinel,
    double? uploadProgress,
    Object? errorMessage = _sentinel,
    Object? uploadedBy = _sentinel,
    Object? uploadedAt = _sentinel,
  }) {
    return StagedFile(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      status: status ?? this.status,
      localPath: identical(localPath, _sentinel)
          ? this.localPath
          : localPath as String?,
      remoteUrl: identical(remoteUrl, _sentinel)
          ? this.remoteUrl
          : remoteUrl as String?,
      mimeType: identical(mimeType, _sentinel)
          ? this.mimeType
          : mimeType as String?,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
      uploadedBy: identical(uploadedBy, _sentinel)
          ? this.uploadedBy
          : uploadedBy as String?,
      uploadedAt: identical(uploadedAt, _sentinel)
          ? this.uploadedAt
          : uploadedAt as DateTime?,
    );
  }

  // ── Factory: from RequirementEvidence (classes feature) ───────────────────

  /// Maps a `RequirementEvidence` to a `StagedFile` with status `uploaded`.
  factory StagedFile.fromRequirementEvidence(classes.RequirementEvidence e) {
    return StagedFile(
      id: e.id,
      name: e.fileName,
      type: e.isImage ? 'image' : 'pdf',
      status: StagedFileStatus.uploaded,
      remoteUrl: e.url,
      mimeType: e.isImage ? 'image/jpeg' : 'application/pdf',
      uploadedBy: e.uploadedByName,
      uploadedAt: e.uploadedAt,
    );
  }

  // ── Factory: from EvidenceFile (evidence folder feature) ──────────────────

  /// Maps an `EvidenceFile` to a `StagedFile` with status `uploaded`.
  factory StagedFile.fromEvidenceFile(evidence.EvidenceFile e) {
    return StagedFile(
      id: e.id,
      name: e.fileName,
      type: e.isImage ? 'image' : 'pdf',
      status: StagedFileStatus.uploaded,
      remoteUrl: e.url,
      mimeType: e.isImage ? 'image/jpeg' : 'application/pdf',
      uploadedBy: e.uploadedByName,
      uploadedAt: e.uploadedAt,
    );
  }

  // ── Factory: from local pick ──────────────────────────────────────────────

  /// Creates a locally staged file from a file path and mime type.
  ///
  /// Uses current microsecond timestamp as a unique local ID.
  factory StagedFile.local({
    required String localPath,
    required String name,
    required String mimeType,
  }) {
    return StagedFile(
      id: 'local_${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      type: mimeType.startsWith('image/') ? 'image' : 'pdf',
      status: StagedFileStatus.local,
      localPath: localPath,
      mimeType: mimeType,
    );
  }

  /// [uploadProgress] is intentionally excluded from [props].
  /// Progress updates are high-frequency and should NOT trigger Equatable
  /// equality checks — the upload sheet reacts to stream events instead.
  @override
  List<Object?> get props => [
        id,
        name,
        type,
        status,
        localPath,
        remoteUrl,
        mimeType,
        // uploadProgress excluded — high-frequency, not identity-relevant
        errorMessage,
        uploadedBy,
        uploadedAt,
      ];
}
```

- [ ] **Step 2: Run `flutter analyze` from the app root to verify the new file compiles cleanly**

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-app && flutter analyze lib/core/widgets/evidence_staging/staged_file.dart
```

- [ ] **Step 3: Commit**

```bash
git add lib/core/widgets/evidence_staging/staged_file.dart
git commit -m "feat: add StagedFile model for evidence staging"
```

---

## Task 2: ImageSourceDialog

**Files:**
- Create: `lib/core/widgets/evidence_staging/image_source_dialog.dart`

- [ ] **Step 1: Create the shared image source dialog extracted from the duplicated code in both detail views**

The dialog is currently copy-pasted in `RequirementDetailView._showImageSourceDialog()` and `EvidenceSectionDetailView._showImageSourceDialog()`. Extract it to a top-level function.

```dart
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';

import '../../theme/app_colors.dart';
import '../../theme/sac_colors.dart';

/// Shows a bottom sheet asking the user to pick an image source.
///
/// Returns [ImageSource.camera] for single capture or
/// [ImageSource.gallery] for multi-select. Returns `null` if dismissed.
Future<ImageSource?> showImageSourceDialog(BuildContext context) {
  return showModalBottomSheet<ImageSource>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: context.sac.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Seleccionar imagen',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedCamera01,
                  size: 22,
                  color: AppColors.primary,
                ),
              ),
            ),
            title: const Text('Cámara'),
            subtitle: const Text('Tomar una foto ahora'),
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedImage01,
                  size: 22,
                  color: AppColors.primary,
                ),
              ),
            ),
            title: const Text('Galería'),
            subtitle: const Text('Elegir de la galería de fotos'),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
          const SizedBox(height: 16),
        ],
      ),
    ),
  );
}
```

- [ ] **Step 2: Run `flutter analyze` to verify**

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-app && flutter analyze lib/core/widgets/evidence_staging/image_source_dialog.dart
```

- [ ] **Step 3: Commit**

```bash
git add lib/core/widgets/evidence_staging/image_source_dialog.dart
git commit -m "refactor: extract shared ImageSourceDialog to evidence_staging"
```

---

## Task 3: StagedFileGrid

**Files:**
- Create: `lib/core/widgets/evidence_staging/staged_file_grid.dart`

- [ ] **Step 1: Create the unified grid widget**

The grid must handle two visual modes based on file status:
- **Remote files (`uploaded`)**: Solid border, green check badge (top-right), uploader name + date at bottom. Tapping opens the viewer (image or PDF). Delete button (top-left red X) shows a confirmation dialog before calling `onDeleteRemote`.
- **Local files (`local`)**: Dashed green border, "Nuevo" green badge (top-right), red X button (top-left) that removes instantly with no confirmation. Tapping opens the local file preview.
- **Excess files**: Same as local but with a red dashed border instead of green.

Grid specs: 3 columns, crossAxisSpacing 10, mainAxisSpacing 10, childAspectRatio 0.82.

Below the grid: file counter `"X de Y archivos"`. If total exceeds maxFiles, show red warning text.

```dart
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';

import '../../theme/app_colors.dart';
import '../../theme/sac_colors.dart';
import '../../widgets/sac_image_viewer.dart';
import '../../widgets/sac_pdf_viewer.dart';
import 'staged_file.dart';

/// Unified grid for displaying both remote (uploaded) and local (staged) files.
///
/// Delete behavior differs by status:
/// - Local files: instant remove (no confirmation).
/// - Remote files: confirmation dialog before calling [onDeleteRemote].
class StagedFileGrid extends StatelessWidget {
  final List<StagedFile> files;
  final int maxFiles;
  final bool canModify;
  final void Function(StagedFile file) onRemoveLocal;
  final void Function(StagedFile file) onDeleteRemote;

  const StagedFileGrid({
    super.key,
    required this.files,
    required this.maxFiles,
    required this.canModify,
    required this.onRemoveLocal,
    required this.onDeleteRemote,
  });

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) return const SizedBox.shrink();

    final c = context.sac;
    final totalFiles = files.length;
    final excess = totalFiles - maxFiles;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.82,
          ),
          itemCount: files.length,
          itemBuilder: (context, index) {
            final file = files[index];
            // A local file is "excess" if its position is beyond maxFiles
            final isExcess =
                file.isLocal && index >= maxFiles;

            return _StagedFileCell(
              file: file,
              isExcess: isExcess,
              canModify: canModify,
              onRemoveLocal: () => onRemoveLocal(file),
              onDeleteRemote: () => _confirmRemoteDelete(context, file),
            );
          },
        ),
        const SizedBox(height: 10),
        // File counter
        Center(
          child: Text(
            '$totalFiles de $maxFiles archivos',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: excess > 0 ? AppColors.error : c.textSecondary,
            ),
          ),
        ),
        // Excess warning
        if (excess > 0) ...[
          const SizedBox(height: 4),
          Center(
            child: Text(
              'Tenés $excess ${excess == 1 ? 'archivo' : 'archivos'} de más, eliminá algunos para continuar',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _confirmRemoteDelete(
      BuildContext context, StagedFile file) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar archivo'),
        content: Text(
          '¿Estás seguro de que deseas eliminar "${file.name}"? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      onDeleteRemote(file);
    }
  }
}

// ── Individual file cell ──────────────────────────────────────────────────────

class _StagedFileCell extends StatelessWidget {
  final StagedFile file;
  final bool isExcess;
  final bool canModify;
  final VoidCallback onRemoveLocal;
  final VoidCallback onDeleteRemote;

  const _StagedFileCell({
    required this.file,
    required this.isExcess,
    required this.canModify,
    required this.onRemoveLocal,
    required this.onDeleteRemote,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sac;
    final dateFormat = DateFormat('d MMM', 'es');

    return GestureDetector(
      onTap: () => _openViewer(context),
      child: Stack(
        children: [
          // Main container
          Container(
            decoration: BoxDecoration(
              color: c.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: file.isLocal
                  ? null // Dashed border handled by CustomPaint below
                  : Border.all(color: c.border),
            ),
            clipBehavior: Clip.antiAlias,
            foregroundDecoration: file.isLocal
                ? _DashedBorderDecoration(
                    color: isExcess ? AppColors.error : AppColors.secondary,
                    borderRadius: BorderRadius.circular(12),
                    strokeWidth: 2,
                    dashWidth: 6,
                    dashGap: 4,
                  )
                : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Thumbnail / icon
                Expanded(child: _buildThumbnail()),

                // Metadata footer
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                  color: c.surface,
                  child: file.isRemote
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              file.uploadedBy ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: c.text,
                              ),
                            ),
                            if (file.uploadedAt != null)
                              Text(
                                dateFormat
                                    .format(file.uploadedAt!.toLocal()),
                                style: TextStyle(
                                  fontSize: 9,
                                  color: c.textTertiary,
                                ),
                              ),
                          ],
                        )
                      : Text(
                          file.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: c.text,
                          ),
                        ),
                ),
              ],
            ),
          ),

          // ── Badges ────────────────────────────────────────────────────────

          // Remote: green check badge (top-right)
          if (file.isRemote)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: c.shadow,
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),

          // Local: "Nuevo" badge (top-right)
          if (file.isLocal)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isExcess ? AppColors.error : AppColors.secondary,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: c.shadow,
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Text(
                  isExcess ? 'Extra' : 'Nuevo',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

          // ── Delete buttons ────────────────────────────────────────────────

          // Local: instant remove (top-left)
          if (file.isLocal && canModify)
            Positioned(
              top: 4,
              left: 4,
              child: GestureDetector(
                onTap: onRemoveLocal,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: c.shadow,
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

          // Remote: delete with confirmation (top-left, only when canModify)
          if (file.isRemote && canModify)
            Positioned(
              top: 4,
              left: 4,
              child: GestureDetector(
                onTap: onDeleteRemote,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: c.shadow,
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildThumbnail() {
    if (file.isPdf) {
      return Container(
        color: AppColors.errorLight,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedPdf01,
              size: 32,
              color: AppColors.error,
            ),
            const SizedBox(height: 4),
            Text(
              'PDF',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.error,
              ),
            ),
          ],
        ),
      );
    }

    // Image thumbnail
    if (file.isRemote && file.remoteUrl != null) {
      return CachedNetworkImage(
        imageUrl: file.remoteUrl!,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => _fallbackIcon(),
        progressIndicatorBuilder: (context, url, downloadProgress) {
          return Container(
            color: AppColors.primaryLight,
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: downloadProgress.progress,
                color: AppColors.primary,
              ),
            ),
          );
        },
      );
    }

    // Local image: show from file
    if (file.isLocal && file.localPath != null) {
      return Image.file(
        File(file.localPath!),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallbackIcon(),
      );
    }

    return _fallbackIcon();
  }

  Widget _fallbackIcon() {
    return Container(
      color: AppColors.primaryLight,
      child: Center(
        child: HugeIcon(
          icon: HugeIcons.strokeRoundedImage01,
          size: 28,
          color: AppColors.primary,
        ),
      ),
    );
  }

  void _openViewer(BuildContext context) {
    if (file.isRemote) {
      if (file.isImage && file.remoteUrl != null) {
        SacImageViewer.show(context, imageUrl: file.remoteUrl!);
      } else if (file.isPdf && file.remoteUrl != null) {
        SacPdfViewer.show(context, pdfUrl: file.remoteUrl!, title: file.name);
      }
    } else if (file.isLocal && file.localPath != null) {
      // Local images: open full-screen preview
      if (file.isImage) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => Scaffold(
              backgroundColor: Colors.black,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                iconTheme: const IconThemeData(color: Colors.white),
              ),
              body: Center(
                child: InteractiveViewer(
                  child: Image.file(
                    File(file.localPath!),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
        );
      }
      // Local PDFs: no preview (would need a local PDF viewer dependency)
    }
  }
}

// ── Dashed border decoration ──────────────────────────────────────────────────

class _DashedBorderDecoration extends Decoration {
  final Color color;
  final BorderRadius borderRadius;
  final double strokeWidth;
  final double dashWidth;
  final double dashGap;

  const _DashedBorderDecoration({
    required this.color,
    required this.borderRadius,
    this.strokeWidth = 2,
    this.dashWidth = 6,
    this.dashGap = 4,
  });

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return _DashedBorderPainter(
      color: color,
      borderRadius: borderRadius,
      strokeWidth: strokeWidth,
      dashWidth: dashWidth,
      dashGap: dashGap,
    );
  }
}

class _DashedBorderPainter extends BoxPainter {
  final Color color;
  final BorderRadius borderRadius;
  final double strokeWidth;
  final double dashWidth;
  final double dashGap;

  _DashedBorderPainter({
    required this.color,
    required this.borderRadius,
    required this.strokeWidth,
    required this.dashWidth,
    required this.dashGap,
  });

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final rect = offset & configuration.size!;
    final rrect = borderRadius.toRRect(rect);
    final path = Path()..addRRect(rrect);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    // Compute dashed path
    final dashedPath = _createDashedPath(path);
    canvas.drawPath(dashedPath, paint);
  }

  Path _createDashedPath(Path source) {
    final result = Path();
    for (final metric in source.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final end = (distance + dashWidth).clamp(0, metric.length).toDouble();
        result.addPath(metric.extractPath(distance, end), Offset.zero);
        distance += dashWidth + dashGap;
      }
    }
    return result;
  }
}
```

- [ ] **Step 2: Run `flutter analyze` to verify**

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-app && flutter analyze lib/core/widgets/evidence_staging/staged_file_grid.dart
```

- [ ] **Step 3: Commit**

```bash
git add lib/core/widgets/evidence_staging/staged_file_grid.dart
git commit -m "feat: add StagedFileGrid with unified remote/local display"
```

---

## Task 4: UploadProgressSheet

**Files:**
- Create: `lib/core/widgets/evidence_staging/upload_progress_sheet.dart`

- [ ] **Step 1: Create the persistent bottom sheet with per-file progress tracking**

The sheet is shown via `showModalBottomSheet` with `isDismissible: false` and `enableDrag: false`. It receives the list of files being uploaded and updates reactively. Three completion states: all success (green header + "Continuar"), partial failure (orange header + 3 buttons), all failed.

```dart
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../theme/app_colors.dart';
import '../../theme/sac_colors.dart';
import 'staged_file.dart';

/// Result returned from the upload progress sheet when it closes.
enum UploadSheetResult {
  /// All files uploaded successfully — proceed to submit.
  continueSubmit,

  /// User chose to continue with only the successfully uploaded files.
  continuePartial,

  /// User chose to retry only the failed files.
  retry,

  /// User cancelled — return to staging (already-uploaded files persist).
  cancelled,
}

/// Shows a persistent bottom sheet tracking upload progress for each file.
///
/// Returns an [UploadSheetResult] indicating the user's chosen action.
///
/// [files] is the list of files being uploaded (only local files in the queue).
/// [uploadStream] is a stream of updated file lists as uploads progress.
/// The caller must drive the upload queue and push updates to the stream.
Future<UploadSheetResult?> showUploadProgressSheet({
  required BuildContext context,
  required List<StagedFile> initialFiles,
  required Stream<List<StagedFile>> uploadStream,
}) {
  return showModalBottomSheet<UploadSheetResult>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _UploadProgressSheetContent(
      initialFiles: initialFiles,
      uploadStream: uploadStream,
    ),
  );
}

class _UploadProgressSheetContent extends StatefulWidget {
  final List<StagedFile> initialFiles;
  final Stream<List<StagedFile>> uploadStream;

  const _UploadProgressSheetContent({
    required this.initialFiles,
    required this.uploadStream,
  });

  @override
  State<_UploadProgressSheetContent> createState() =>
      _UploadProgressSheetContentState();
}

class _UploadProgressSheetContentState
    extends State<_UploadProgressSheetContent> {
  late List<StagedFile> _files;

  @override
  void initState() {
    super.initState();
    _files = List.from(widget.initialFiles);
    widget.uploadStream.listen((updatedFiles) {
      if (mounted) {
        setState(() => _files = updatedFiles);
      }
    });
  }

  // ── Computed state ──────────────────────────────────────────────────────────

  int get _completedCount =>
      _files.where((f) => f.status == StagedFileStatus.completed).length;
  int get _errorCount =>
      _files.where((f) => f.status == StagedFileStatus.error).length;
  int get _uploadingCount =>
      _files.where((f) => f.status == StagedFileStatus.uploading).length;
  int get _pendingCount =>
      _files.where((f) => f.status == StagedFileStatus.local).length;

  bool get _isInProgress => _uploadingCount > 0 || _pendingCount > 0;
  bool get _allDone => !_isInProgress;
  bool get _allSuccess => _allDone && _errorCount == 0;
  bool get _hasErrors => _allDone && _errorCount > 0;
  bool get _allFailed => _allDone && _completedCount == 0 && _errorCount > 0;

  double get _overallProgress {
    if (_files.isEmpty) return 0;
    final total = _files.length.toDouble();
    final completed = _completedCount.toDouble();
    // Add partial progress from the currently uploading file
    final uploading = _files.where((f) => f.status == StagedFileStatus.uploading);
    final partialProgress =
        uploading.fold<double>(0, (sum, f) => sum + f.uploadProgress);
    return (completed + partialProgress) / total;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sac;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: c.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            _buildHeader(c),
            const SizedBox(height: 12),

            // Overall progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _overallProgress,
                minHeight: 6,
                backgroundColor: c.surfaceVariant,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _hasErrors
                      ? AppColors.accent
                      : _allSuccess
                          ? AppColors.secondary
                          : AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // File list
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.35,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _files.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: c.divider,
                ),
                itemBuilder: (context, index) =>
                    _FileProgressRow(file: _files[index]),
              ),
            ),

            const SizedBox(height: 16),

            // Action buttons
            if (_allDone) _buildActionButtons(c),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(SacColors c) {
    if (_isInProgress) {
      return Text(
        'Subiendo ${_completedCount + 1} de ${_files.length} archivos...',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: c.text,
        ),
      );
    }
    if (_allSuccess) {
      return Text(
        'Todos los archivos subidos',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.secondary,
        ),
      );
    }
    if (_allFailed) {
      return Text(
        'Todos los archivos fallaron',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.error,
        ),
      );
    }
    // Partial failure
    return Text(
      '$_completedCount de ${_files.length} subidos, $_errorCount fallaron',
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.accentDark,
      ),
    );
  }

  Widget _buildActionButtons(SacColors c) {
    if (_allSuccess) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: () =>
              Navigator.pop(context, UploadSheetResult.continueSubmit),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.secondary,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Continuar',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    // Partial failure or all failed: 3 buttons
    return Column(
      children: [
        // Retry failed — returns UploadSheetResult.retry so the manager
        // can re-run uploads for only the failed files.
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () =>
                Navigator.pop(context, UploadSheetResult.retry),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Reintentar fallidos ($_errorCount)',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ),

        // Continue with uploaded (only if some succeeded)
        if (!_allFailed) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _confirmContinuePartial(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(color: AppColors.secondary, width: 1.5),
              ),
              child: Text(
                'Continuar con los subidos ($_completedCount)',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppColors.secondary,
                ),
              ),
            ),
          ),
        ],

        // Cancel
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () =>
                Navigator.pop(context, UploadSheetResult.cancelled),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(
              'Cancelar',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: c.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmContinuePartial(BuildContext ctx) async {
    final confirm = await showDialog<bool>(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Continuar sin todos los archivos'),
        content: Text(
          'Los $_errorCount archivos que fallaron no se incluirán en la validación.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.secondary,
            ),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      Navigator.pop(context, UploadSheetResult.continuePartial);
    }
  }
}

// ── Individual file row ────────────────────────────────────────────────────────

class _FileProgressRow extends StatelessWidget {
  final StagedFile file;

  const _FileProgressRow({required this.file});

  @override
  Widget build(BuildContext context) {
    final c = context.sac;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          // File type icon
          HugeIcon(
            icon: file.isImage
                ? HugeIcons.strokeRoundedImage01
                : HugeIcons.strokeRoundedPdf01,
            size: 20,
            color: file.isImage ? AppColors.primary : AppColors.error,
          ),
          const SizedBox(width: 10),

          // File name
          Expanded(
            child: Text(
              file.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: c.text,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Status indicator
          _buildStatusIndicator(c),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(SacColors c) {
    switch (file.status) {
      case StagedFileStatus.local:
        // Pending: yellow dot
        return Container(
          width: 10,
          height: 10,
          decoration: const BoxDecoration(
            color: AppColors.accent,
            shape: BoxShape.circle,
          ),
        );

      case StagedFileStatus.uploading:
        // Uploading: blue dot + percentage
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: AppColors.sacBlue,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${(file.uploadProgress * 100).toInt()}%',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.sacBlue,
              ),
            ),
          ],
        );

      case StagedFileStatus.completed:
        // Completed: green check
        return const Icon(
          Icons.check_circle_rounded,
          size: 18,
          color: AppColors.secondary,
        );

      case StagedFileStatus.error:
        // Error: red X
        return const Icon(
          Icons.error_rounded,
          size: 18,
          color: AppColors.error,
        );

      case StagedFileStatus.uploaded:
        // Should not appear in upload sheet, but handle gracefully
        return const Icon(
          Icons.check_circle_rounded,
          size: 18,
          color: AppColors.secondary,
        );
    }
  }
}
```

- [ ] **Step 2: Run `flutter analyze` to verify**

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-app && flutter analyze lib/core/widgets/evidence_staging/upload_progress_sheet.dart
```

- [ ] **Step 3: Commit**

```bash
git add lib/core/widgets/evidence_staging/upload_progress_sheet.dart
git commit -m "feat: add UploadProgressSheet with per-file progress tracking"
```

---

## Task 5: Wire onProgress Callback Through Data Layer

**Files:**
- Modify: `lib/features/classes/data/datasources/classes_remote_data_source.dart`
- Modify: `lib/features/classes/data/repositories/classes_repository_impl.dart`
- Modify: `lib/features/classes/domain/repositories/classes_repository.dart`
- Modify: `lib/features/classes/domain/usecases/upload_requirement_file.dart`
- Modify: `lib/features/classes/presentation/providers/classes_providers.dart`
- Modify: `lib/features/evidence_folder/data/datasources/evidence_folder_remote_data_source.dart`
- Modify: `lib/features/evidence_folder/data/repositories/evidence_folder_repository_impl.dart`
- Modify: `lib/features/evidence_folder/domain/repositories/evidence_folder_repository.dart`
- Modify: `lib/features/evidence_folder/domain/usecases/upload_evidence_file.dart`
- Modify: `lib/features/evidence_folder/presentation/providers/evidence_folder_providers.dart`

Both features already have `onSendProgress` in their Dio `.post()` calls, but it is only used for logging — never wired to an external callback. This task threads an `onProgress` callback from the notifier all the way down to Dio.

**C-2 fix (skipInvalidation)** is also applied here: both notifiers get a `skipInvalidation` parameter that, when `true`, skips the `ref.invalidate()` call after upload. The staging manager passes `skipInvalidation: true` during batch uploads, then triggers a single invalidation after the entire batch via the `onSubmit` callback.

- [ ] **Step 1: Classes feature — data source**

Add an optional `onProgress` callback to `ClassesRemoteDataSourceImpl.uploadRequirementFile()` and its abstract interface:

```dart
// Abstract (classes_remote_data_source.dart):
Future<RequirementEvidenceModel> uploadRequirementFile({
  required String userId,
  required int classId,
  required int requirementId,
  required String filePath,
  required String fileName,
  required String mimeType,
  void Function(double)? onProgress,  // NEW
});

// Impl — wire onSendProgress in the Dio .post() call:
onSendProgress: (sent, total) {
  if (total > 0) {
    final fraction = sent / total;
    onProgress?.call(fraction);
    AppLogger.d(
      'Upload progress: ${(fraction * 100).toStringAsFixed(1)}%',
      tag: _tag,
    );
  }
},
```

- [ ] **Step 2: Classes feature — repository**

Pass through `onProgress` in `ClassesRepositoryImpl.uploadRequirementFile()` and its abstract interface:

```dart
// Abstract (classes_repository.dart):
Future<Either<Failure, RequirementEvidence>> uploadRequirementFile({
  required String userId,
  required int classId,
  required int requirementId,
  required String filePath,
  required String fileName,
  required String mimeType,
  void Function(double)? onProgress,  // NEW
});

// Impl — pass through to data source:
final model = await remoteDataSource.uploadRequirementFile(
  userId: userId,
  classId: classId,
  requirementId: requirementId,
  filePath: filePath,
  fileName: fileName,
  mimeType: mimeType,
  onProgress: onProgress,  // NEW
);
```

- [ ] **Step 3: Classes feature — use case**

Add `onProgress` to `UploadRequirementFileParams` and pass through:

```dart
class UploadRequirementFileParams {
  // ... existing fields ...
  final void Function(double)? onProgress;  // NEW

  const UploadRequirementFileParams({
    // ... existing params ...
    this.onProgress,  // NEW
  });
}

// In call():
return _repository.uploadRequirementFile(
  userId: params.userId,
  classId: params.classId,
  requirementId: params.requirementId,
  filePath: params.filePath,
  fileName: params.fileName,
  mimeType: params.mimeType,
  onProgress: params.onProgress,  // NEW
);
```

- [ ] **Step 4: Classes feature — notifier (RequirementNotifier)**

Add `onProgress` and `skipInvalidation` to `uploadFile()`:

```dart
Future<bool> uploadFile({
  required int requirementId,
  required XFile pickedFile,
  required String mimeType,
  void Function(double)? onProgress,   // NEW (C-1)
  bool skipInvalidation = false,        // NEW (C-2)
}) async {
  state = state.copyWith(isLoading: true, errorMessage: null, success: false);

  final result = await ref.read(uploadRequirementFileUseCaseProvider)(
    UploadRequirementFileParams(
      userId: _userId,
      classId: _classId,
      requirementId: requirementId,
      filePath: pickedFile.path,
      fileName: pickedFile.name,
      mimeType: mimeType,
      onProgress: onProgress,  // NEW
    ),
  );

  return result.fold(
    (failure) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      );
      return false;
    },
    (_) {
      state = state.copyWith(isLoading: false, success: true);
      if (!skipInvalidation) {                          // NEW (C-2)
        ref.invalidate(classWithProgressProvider(_classId));
      }
      return true;
    },
  );
}
```

- [ ] **Step 5: Evidence folder feature — data source**

Same pattern as Step 1. Add `onProgress` to `EvidenceFolderRemoteDataSourceImpl.uploadFile()` and its abstract interface:

```dart
// Abstract:
Future<EvidenceFileModel> uploadFile({
  required String clubSectionId,
  required String sectionId,
  required String filePath,
  required String fileName,
  required String mimeType,
  void Function(double)? onProgress,  // NEW
});

// Impl — wire onSendProgress:
onSendProgress: (sent, total) {
  if (total > 0) {
    final fraction = sent / total;
    onProgress?.call(fraction);
    AppLogger.d(
      'Upload progress: ${(fraction * 100).toStringAsFixed(1)}%',
      tag: _tag,
    );
  }
},
```

- [ ] **Step 6: Evidence folder feature — repository**

Pass through `onProgress`:

```dart
// Abstract:
Future<Either<Failure, EvidenceFile>> uploadFile({
  required String clubSectionId,
  required String sectionId,
  required String filePath,
  required String fileName,
  required String mimeType,
  void Function(double)? onProgress,  // NEW
});

// Impl:
final model = await remoteDataSource.uploadFile(
  clubSectionId: clubSectionId,
  sectionId: sectionId,
  filePath: filePath,
  fileName: fileName,
  mimeType: mimeType,
  onProgress: onProgress,  // NEW
);
```

- [ ] **Step 7: Evidence folder feature — use case**

Add `onProgress` to `UploadEvidenceFileParams` and pass through:

```dart
class UploadEvidenceFileParams {
  // ... existing fields ...
  final void Function(double)? onProgress;  // NEW

  const UploadEvidenceFileParams({
    // ... existing params ...
    this.onProgress,  // NEW
  });
}

// In call():
return _repository.uploadFile(
  clubSectionId: params.clubSectionId,
  sectionId: params.sectionId,
  filePath: params.filePath,
  fileName: params.fileName,
  mimeType: params.mimeType,
  onProgress: params.onProgress,  // NEW
);
```

- [ ] **Step 8: Evidence folder feature — notifier (EvidenceSectionNotifier)**

Add `onProgress` and `skipInvalidation` to `uploadFile()`:

```dart
Future<bool> uploadFile({
  required String sectionId,
  required XFile pickedFile,
  required String mimeType,
  void Function(double)? onProgress,   // NEW (C-1)
  bool skipInvalidation = false,        // NEW (C-2)
}) async {
  state = state.copyWith(isLoading: true, errorMessage: null, success: false);

  final result = await ref.read(uploadEvidenceFileUseCaseProvider)(
    UploadEvidenceFileParams(
      clubSectionId: _clubSectionId,
      sectionId: sectionId,
      filePath: pickedFile.path,
      fileName: pickedFile.name,
      mimeType: mimeType,
      onProgress: onProgress,  // NEW
    ),
  );

  return result.fold(
    (failure) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      );
      return false;
    },
    (_) {
      state = state.copyWith(isLoading: false, success: true);
      if (!skipInvalidation) {                                  // NEW (C-2)
        ref.invalidate(evidenceFolderProvider(_clubSectionId));
      }
      return true;
    },
  );
}
```

- [ ] **Step 9: Run `flutter analyze` to verify both features**

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-app && flutter analyze lib/features/classes/ lib/features/evidence_folder/
```

- [ ] **Step 10: Commit**

```bash
git add lib/features/classes/data/datasources/classes_remote_data_source.dart \
  lib/features/classes/data/repositories/classes_repository_impl.dart \
  lib/features/classes/domain/repositories/classes_repository.dart \
  lib/features/classes/domain/usecases/upload_requirement_file.dart \
  lib/features/classes/presentation/providers/classes_providers.dart \
  lib/features/evidence_folder/data/datasources/evidence_folder_remote_data_source.dart \
  lib/features/evidence_folder/data/repositories/evidence_folder_repository_impl.dart \
  lib/features/evidence_folder/domain/repositories/evidence_folder_repository.dart \
  lib/features/evidence_folder/domain/usecases/upload_evidence_file.dart \
  lib/features/evidence_folder/presentation/providers/evidence_folder_providers.dart
git commit -m "feat: wire onProgress callback and skipInvalidation through upload chain"
```

---

## Task 6: EvidenceStagingManager

> **Depends on:** Task 5 (onProgress + skipInvalidation must exist before integration)

**Files:**
- Create: `lib/core/widgets/evidence_staging/evidence_staging_manager.dart`

- [ ] **Step 1: Create the main orchestrator widget**

This is the core widget consumed by both integration points. It manages:
- Combining `existingFiles` (remote, passed in) with locally staged files
- Multi-select image picker (gallery) and single camera capture via `showImageSourceDialog`
- Multi-select PDF picker via `FilePicker`
- Limit validation (total files vs `maxFiles`)
- Sequential upload queue execution with progress tracking per file
- Integration with `UploadProgressSheet`
- Bottom action bar with Imagen/PDF/Enviar buttons
- Disabled state when `canModify` is false

State management: `StatefulWidget` + `setState`. No Riverpod.

```dart
import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';

import '../../theme/app_colors.dart';
import '../../theme/sac_colors.dart';
import '../../utils/app_logger.dart';
import '../sac_button.dart';
import 'image_source_dialog.dart';
import 'staged_file.dart';
import 'staged_file_grid.dart';
import 'upload_progress_sheet.dart';

/// Main orchestrator widget for evidence file staging.
///
/// Consumed by both `RequirementDetailView` (classes) and
/// `EvidenceSectionDetailView` (evidence folders). Each integration point
/// maps its domain entities to [StagedFile] before passing them in.
///
/// Internal state is managed via `StatefulWidget` + `setState`.
/// Riverpod notifiers are used only in the parent screens.
class EvidenceStagingManager extends StatefulWidget {
  /// Already-uploaded files — the caller maps domain entities to
  /// `StagedFile(status: uploaded)` before passing them here.
  final List<StagedFile> existingFiles;

  /// Maximum number of files allowed (remote + local combined).
  final int maxFiles;

  /// Callback to upload a single file. Receives an [XFile], its mime type,
  /// and an `onProgress` callback that the caller should wire to Dio's
  /// `onSendProgress` to report upload progress (0.0 to 1.0).
  final Future<void> Function(
    XFile file,
    String mimeType,
    void Function(double progress) onProgress,
  ) onUpload;

  /// Callback to delete an already-uploaded file from the server.
  final Future<void> Function(String fileId) onDeleteRemote;

  /// Callback to mark the requirement/section as submitted for validation.
  final Future<void> Function() onSubmit;

  /// Builds a descriptive file name for backend/storage.
  /// [originalName] is the picked file's name, [index] is the absolute
  /// position in the full file list (remote count + local position), 1-based.
  final String Function(String originalName, int index) fileNameBuilder;

  /// False when the requirement/section status is not `pendiente`.
  /// Disables all modification controls.
  final bool canModify;

  /// Whether the notifier is currently loading (submit, delete, etc.).
  /// Used to disable the action bar while operations are in progress.
  final bool isLoading;

  /// Called whenever the count of local (unsaved) files changes.
  /// The parent can use this to update `PopScope.canPop` without a GlobalKey.
  final void Function(bool hasLocalFiles)? onLocalFilesChanged;

  const EvidenceStagingManager({
    super.key,
    required this.existingFiles,
    required this.maxFiles,
    required this.onUpload,
    required this.onDeleteRemote,
    required this.onSubmit,
    required this.fileNameBuilder,
    required this.canModify,
    this.isLoading = false,
    this.onLocalFilesChanged,
  });

  @override
  State<EvidenceStagingManager> createState() => EvidenceStagingManagerState();
}

class EvidenceStagingManagerState extends State<EvidenceStagingManager> {
  final _picker = ImagePicker();

  /// Combined list: remote files first, then locally staged files.
  late List<StagedFile> _allFiles;

  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _allFiles = List.from(widget.existingFiles);
  }

  @override
  void didUpdateWidget(covariant EvidenceStagingManager oldWidget) {
    super.didUpdateWidget(oldWidget);
    // When parent rebuilds with new existing files (e.g. after provider
    // invalidation), merge them with any remaining local files.
    if (oldWidget.existingFiles != widget.existingFiles) {
      final localFiles =
          _allFiles.where((f) => f.isLocal).toList();
      _allFiles = [...widget.existingFiles, ...localFiles];
    }
  }

  // ── Computed ────────────────────────────────────────────────────────────────

  List<StagedFile> get _localFiles =>
      _allFiles.where((f) => f.isLocal).toList();

  bool get _hasLocalFiles => _localFiles.isNotEmpty;

  bool get _hasAnyFiles => _allFiles.isNotEmpty;

  bool get _isOverLimit => _allFiles.length > widget.maxFiles;

  /// Whether the "Enviar" button should be enabled.
  bool get _canSubmit =>
      widget.canModify &&
      !_isUploading &&
      _hasAnyFiles &&
      !_isOverLimit;

  /// Notifies the parent whenever the local file count changes.
  /// Used for PopScope without GlobalKey (I-2 fix).
  void _notifyLocalFilesChanged() {
    widget.onLocalFilesChanged?.call(_hasLocalFiles);
  }

  // ── File picking ──────────────────────────────────────────────────────────

  Future<void> _pickImages(BuildContext context) async {
    final source = await showImageSourceDialog(context);
    if (source == null || !mounted) return;

    try {
      final List<XFile> pickedFiles;
      if (source == ImageSource.camera) {
        final single = await _picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 85,
          maxWidth: 2048,
          maxHeight: 2048,
        );
        pickedFiles = single != null ? [single] : [];
      } else {
        pickedFiles = await _picker.pickMultiImage(
          imageQuality: 85,
          maxWidth: 2048,
          maxHeight: 2048,
        );
      }

      if (pickedFiles.isEmpty || !mounted) return;

      // I-3: Never mutate _allFiles in place — always create a new list.
      setState(() {
        final newFiles = pickedFiles.map((picked) {
          final mimeType = picked.name.toLowerCase().endsWith('.png')
              ? 'image/png'
              : 'image/jpeg';
          return StagedFile.local(
            localPath: picked.path,
            name: picked.name,
            mimeType: mimeType,
          );
        }).toList();
        _allFiles = [..._allFiles, ...newFiles];
      });
      _notifyLocalFilesChanged();
    } catch (e) {
      AppLogger.e('Error al seleccionar imagen', error: e);
      if (mounted) {
        _showErrorSnackbar(context, 'No se pudo seleccionar la imagen.');
      }
    }
  }

  Future<void> _pickPdfs(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: true,
      );
      if (result == null || result.files.isEmpty || !mounted) return;

      // I-3: Never mutate _allFiles in place — always create a new list.
      setState(() {
        final newFiles = result.files
            .where((pf) => pf.path != null)
            .map((pf) => StagedFile.local(
                  localPath: pf.path!,
                  name: pf.name,
                  mimeType: 'application/pdf',
                ))
            .toList();
        _allFiles = [..._allFiles, ...newFiles];
      });
      _notifyLocalFilesChanged();
    } catch (e) {
      AppLogger.e('Error al seleccionar PDF', error: e);
      if (mounted) {
        _showErrorSnackbar(context, 'No se pudo seleccionar el PDF.');
      }
    }
  }

  // ── Local file removal ──────────────────────────────────────────────────────

  // I-3: Never mutate _allFiles in place — always create a new list.
  void _removeLocalFile(StagedFile file) {
    setState(() {
      _allFiles = _allFiles.where((f) => f.id != file.id).toList();
    });
    _notifyLocalFilesChanged();
  }

  // ── Remote file deletion ──────────────────────────────────────────────────

  // I-3: Never mutate _allFiles in place — always create a new list.
  Future<void> _deleteRemoteFile(StagedFile file) async {
    try {
      await widget.onDeleteRemote(file.id);
      if (mounted) {
        setState(() {
          _allFiles = _allFiles.where((f) => f.id != file.id).toList();
        });
      }
    } catch (e) {
      AppLogger.e('Error al eliminar archivo', error: e);
      if (mounted) {
        _showErrorSnackbar(context, 'No se pudo eliminar el archivo.');
      }
    }
  }

  // ── Upload + Submit flow ──────────────────────────────────────────────────

  Future<void> _submitForValidation(BuildContext context) async {
    // If no local files, skip upload and go straight to submit
    if (!_hasLocalFiles) {
      await _confirmAndSubmit(context);
      return;
    }

    // If over limit, block
    if (_isOverLimit) {
      _showErrorSnackbar(
        context,
        'Tenés archivos de más. Eliminá algunos para continuar.',
      );
      return;
    }

    // Confirm intent
    final confirm = await _showSubmitConfirmDialog(context);
    if (!confirm || !mounted) return;

    // Execute upload queue with progress sheet
    await _executeUploadQueue(context);
  }

  Future<void> _executeUploadQueue(BuildContext context) async {
    setState(() => _isUploading = true);

    // Prepare the upload stream controller
    final streamController = StreamController<List<StagedFile>>.broadcast();

    // Assign file names with proper indexes
    final remoteCount =
        _allFiles.where((f) => f.status == StagedFileStatus.uploaded).length;
    final localFiles = _localFiles;

    // Show the progress sheet
    final sheetResultFuture = showUploadProgressSheet(
      context: context,
      initialFiles: localFiles,
      uploadStream: streamController.stream,
    );

    // Execute uploads sequentially
    for (int i = 0; i < localFiles.length; i++) {
      final file = localFiles[i];
      final fileIndex = remoteCount + i + 1;
      final fileName =
          widget.fileNameBuilder(file.name, fileIndex);

      // Transition to uploading
      _updateFileStatus(
        file.id,
        StagedFileStatus.uploading,
        uploadProgress: 0.0,
      );
      streamController.add(_localFiles);

      try {
        final xFile = XFile(
          file.localPath!,
          name: fileName,
          mimeType: file.mimeType,
        );

        await widget.onUpload(
          xFile,
          file.mimeType ?? 'application/octet-stream',
          (progress) {
            _updateFileStatus(
              file.id,
              StagedFileStatus.uploading,
              uploadProgress: progress,
            );
            streamController.add(_localFiles);
          },
        );

        // Success
        _updateFileStatus(file.id, StagedFileStatus.completed);
        streamController.add(_localFiles);
      } catch (e) {
        AppLogger.e('Error uploading file: ${file.name}', error: e);
        _updateFileStatus(
          file.id,
          StagedFileStatus.error,
          errorMessage: e.toString(),
        );
        streamController.add(_localFiles);
      }
    }

    // Wait for user action on the sheet
    final sheetResult = await sheetResultFuture;
    await streamController.close();

    if (!mounted) return;

    setState(() => _isUploading = false);

    // I-3: Never mutate _allFiles in place — always create a new list.
    switch (sheetResult) {
      case UploadSheetResult.continueSubmit:
      case UploadSheetResult.continuePartial:
        // Remove local files that were completed (they're now on server)
        setState(() {
          _allFiles = _allFiles.where((f) {
            if (f.status == StagedFileStatus.completed) return false;
            if (sheetResult == UploadSheetResult.continuePartial &&
                f.status == StagedFileStatus.error) return false;
            return true;
          }).toList();
        });
        // Proceed to submit
        await widget.onSubmit();
        break;

      // C-3: Retry actually re-runs the upload loop for failed files.
      case UploadSheetResult.retry:
        // Reset failed files back to uploading and re-run the loop
        setState(() {
          _allFiles = _allFiles.map((f) {
            if (f.status == StagedFileStatus.error) {
              return f.copyWith(
                status: StagedFileStatus.local,
                uploadProgress: 0.0,
                errorMessage: null,
              );
            }
            return f;
          }).toList();
        });
        // Recursively re-run the upload queue for the remaining local files
        if (_hasLocalFiles && mounted) {
          await _executeUploadQueue(context);
        }
        break;

      case UploadSheetResult.cancelled:
        // Return failed files to local status for manual re-staging
        setState(() {
          _allFiles = _allFiles.map((f) {
            if (f.status == StagedFileStatus.error) {
              return f.copyWith(
                status: StagedFileStatus.local,
                uploadProgress: 0.0,
                errorMessage: null,
              );
            }
            if (f.status == StagedFileStatus.completed) {
              // Already uploaded — will appear as remote on next refresh
              return f;
            }
            return f;
          }).toList();
        });
        break;

      case null:
        break;
    }
  }

  /// Updates a file's status in the list. Creates a new list (I-3).
  ///
  /// With the sentinel copyWith pattern (I-1), passing `null` for
  /// [errorMessage] explicitly clears it, while omitting it preserves
  /// the existing value. Here we always pass it through since every
  /// status transition has clear intent:
  /// - `uploading` / `completed`: errorMessage is null -> clears previous error
  /// - `error`: errorMessage is set -> stores the error
  void _updateFileStatus(
    String fileId,
    StagedFileStatus status, {
    double? uploadProgress,
    String? errorMessage,
  }) {
    setState(() {
      _allFiles = _allFiles.map((f) {
        if (f.id == fileId) {
          return f.copyWith(
            status: status,
            uploadProgress: uploadProgress ?? f.uploadProgress,
            errorMessage: errorMessage,
          );
        }
        return f;
      }).toList();
    });
    _notifyLocalFilesChanged();
  }

  // ── Dialogs ─────────────────────────────────────────────────────────────────

  Future<void> _confirmAndSubmit(BuildContext context) async {
    final confirm = await _showSubmitConfirmDialog(context);
    if (!confirm || !mounted) return;
    await widget.onSubmit();
  }

  Future<bool> _showSubmitConfirmDialog(BuildContext context) async {
    final totalFiles = _allFiles.length;
    final newFiles = _localFiles.length;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enviar a validación'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Una vez enviado, no podrás modificar los archivos hasta recibir retroalimentación.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Text(
              'Archivos totales: $totalFiles'
              '${newFiles > 0 ? ' ($newFiles nuevos por subir)' : ''}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.secondary,
            ),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showErrorSnackbar(BuildContext context, String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded,
                color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  // I-2: The action bar is built directly inside this widget's build method,
  // eliminating the need for a GlobalKey<EvidenceStagingManagerState> in the
  // parent. The parent Scaffold should NOT use bottomNavigationBar — instead,
  // this widget outputs both the grid and the action bar in a single Column.
  // I-5: No mid-batch invalidation issue since C-2 (skipInvalidation) ensures
  // providers are not invalidated during batch uploads. A single invalidation
  // happens after the full batch via the onSubmit callback.

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Scrollable content area
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _allFiles.isEmpty
                ? _EmptyFiles(canModify: widget.canModify)
                : StagedFileGrid(
                    files: _allFiles,
                    maxFiles: widget.maxFiles,
                    canModify: widget.canModify,
                    onRemoveLocal: _removeLocalFile,
                    onDeleteRemote: _deleteRemoteFile,
                  ),
          ),
        ),

        // Action bar — always at the bottom, no GlobalKey needed
        if (widget.canModify)
          _EvidenceStagingActionBar(
            onPickImages: () => _pickImages(context),
            onPickPdfs: () => _pickPdfs(context),
            onSubmit: () => _submitForValidation(context),
            canSubmit: _canSubmit,
            isLoading: widget.isLoading || _isUploading,
          ),
      ],
    );
  }
}

// ── Empty state ──────────────────────────────────────────────────────────────

class _EmptyFiles extends StatelessWidget {
  final bool canModify;

  const _EmptyFiles({required this.canModify});

  @override
  Widget build(BuildContext context) {
    final c = context.sac;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedFiles01,
            size: 48,
            color: c.textTertiary,
          ),
          const SizedBox(height: 12),
          Text(
            canModify
                ? 'Aún no hay archivos. Usá los botones de abajo para agregar evidencias.'
                : 'No hay archivos de evidencia.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: c.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// I-2: Bottom action bar is now a private widget inside the manager file.
/// It takes simple callbacks instead of requiring access to the manager's state
/// via a GlobalKey. The parent screen never needs to reference the manager state.
class _EvidenceStagingActionBar extends StatelessWidget {
  final VoidCallback onPickImages;
  final VoidCallback onPickPdfs;
  final VoidCallback onSubmit;
  final bool canSubmit;
  final bool isLoading;

  const _EvidenceStagingActionBar({
    required this.onPickImages,
    required this.onPickPdfs,
    required this.onSubmit,
    required this.canSubmit,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sac;

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.border)),
        boxShadow: [
          BoxShadow(
            color: c.shadow,
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Upload buttons row
          Row(
            children: [
              Expanded(
                child: SacButton.outline(
                  text: 'Imagen',
                  icon: HugeIcons.strokeRoundedCamera01,
                  isEnabled: !isLoading,
                  onPressed: !isLoading ? onPickImages : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SacButton.outline(
                  text: 'PDF',
                  icon: HugeIcons.strokeRoundedPdf01,
                  isEnabled: !isLoading,
                  onPressed: !isLoading ? onPickPdfs : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Submit button
          SacButton.primary(
            text: 'Enviar a validación',
            icon: HugeIcons.strokeRoundedSent,
            isEnabled: canSubmit && !isLoading,
            isLoading: isLoading,
            onPressed: canSubmit && !isLoading ? onSubmit : null,
          ),
        ],
      ),
    );
  }
}
```

**Important design note about `_EvidenceStagingActionBar`**: The action bar is now a private widget built directly inside `EvidenceStagingManagerState.build()`. This eliminates the need for a `GlobalKey<EvidenceStagingManagerState>` in the parent (I-2 fix). The parent screen uses `EvidenceStagingManager` as a single widget that outputs both the grid and the action bar — the Scaffold should NOT use `bottomNavigationBar` for the action bar. Instead, the `EvidenceStagingManager` goes inside the Scaffold `body` and fills the available space with `Expanded`.

- [ ] **Step 2: Run `flutter analyze` to verify**

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-app && flutter analyze lib/core/widgets/evidence_staging/evidence_staging_manager.dart
```

- [ ] **Step 3: Fix any analyzer issues**

The `_EvidenceStagingActionBar` is now a private widget that takes simple `VoidCallback`s — no access to manager state needed. The action bar is built inside `EvidenceStagingManagerState.build()` which passes its own methods as callbacks. No private member access issues.

- [ ] **Step 4: Commit**

```bash
git add lib/core/widgets/evidence_staging/evidence_staging_manager.dart
git commit -m "feat: add EvidenceStagingManager orchestrator widget"
```

---

## Task 7: SacButton Disabled Style Fix

**Files:**
- Modify: `lib/core/widgets/sac_button.dart`

- [ ] **Step 1: Read the current `sac_button.dart` to confirm the existing structure**

Read: `lib/core/widgets/sac_button.dart`

The issue: `_backgroundColor` and `_foregroundColor` are resolved as getters outside `build()`, using static `AppColors` constants. The disabled state in `ButtonStyle.backgroundColor` uses `_backgroundColor.withValues(alpha: 0.5)` which produces a faded version of the theme color — resulting in a gray-red mess for outline buttons. The border side `_borderSide` always uses `AppColors.primary` even when disabled.

- [ ] **Step 2: Refactor the `build` method to use `context.sac` theme tokens for disabled state**

The structural change:
1. Move the disabled color resolution INSIDE the `build()` method where `context` is available.
2. When `_effectivelyDisabled` is true, override:
   - `backgroundColor` -> `context.sac.surface` (very light, neutral)
   - `foregroundColor` (text/icon) -> `context.sac.textTertiary` (muted)
   - `border` -> `context.sac.border` (neutral)
3. Remove the `AnimatedOpacity` wrapper (I-4 fix) — it wraps with `opacity: 1.0` which is a no-op. Disabled transition is handled via instant color changes on `setState`.

Replace the `build` method in `_SacButtonState`:

```dart
@override
Widget build(BuildContext context) {
  final c = context.sac;

  // ── Resolve disabled colors using theme tokens ──────────────────────
  final effectiveBg = _effectivelyDisabled ? c.surface : _backgroundColor;
  final effectiveFg = _effectivelyDisabled ? c.textTertiary : _foregroundColor;
  final effectiveBorder = _effectivelyDisabled
      ? BorderSide(color: c.border, width: 1.5)
      : (_borderSide ?? BorderSide.none);

  final shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(_borderRadius),
    side: effectiveBorder,
  );

  final style = ButtonStyle(
    backgroundColor: WidgetStateProperty.all(effectiveBg),
    foregroundColor: WidgetStateProperty.all(effectiveFg),
    overlayColor: WidgetStateProperty.all(
      effectiveFg.withValues(alpha: 0.1),
    ),
    elevation: WidgetStateProperty.all(0),
    padding: WidgetStateProperty.all(_padding),
    minimumSize: WidgetStateProperty.all(
      Size(widget.fullWidth ? double.infinity : 0, _minHeight),
    ),
    shape: WidgetStateProperty.all(shape),
    textStyle: WidgetStateProperty.all(
      TextStyle(fontSize: _fontSize, fontWeight: FontWeight.w600),
    ),
  );

  final child = widget.isLoading
      ? SizedBox(
          height: _iconSize,
          width: _iconSize,
          child: CircularProgressIndicator(
            color: effectiveFg,
            strokeWidth: 2.0,
          ),
        )
      : Row(
          mainAxisSize:
              widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.icon != null) ...[
              buildIcon(widget.icon,
                  size: _iconSize, color: effectiveFg),
              SizedBox(width: widget.spaceBetween),
            ],
            Flexible(
              child: Text(
                widget.text,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (widget.trailingIcon != null) ...[
              SizedBox(width: widget.spaceBetween),
              buildIcon(widget.trailingIcon,
                  size: _iconSize, color: effectiveFg),
            ],
          ],
        );

  Widget button;
  if (widget.variant == SacButtonVariant.ghost) {
    button = TextButton(
      onPressed: _effectivelyDisabled ? null : widget.onPressed,
      style: style,
      child: child,
    );
  } else {
    button = ElevatedButton(
      onPressed: _effectivelyDisabled ? null : widget.onPressed,
      style: style,
      child: child,
    );
  }

  // I-4: No AnimatedOpacity wrapper — opacity is always 1.0 so it's a no-op.
  // Disabled state is handled via color changes which are instant on setState.
  // The ScaleTransition below provides the only intentional animation.

  // Scale animation on press with haptic feedback
  return GestureDetector(
    onTapDown: _handleTapDown,
    onTapUp: _handleTapUp,
    onTapCancel: _handleTapCancel,
    child: ScaleTransition(
      scale: _scaleAnimation,
      child: button,
    ),
  );
}
```

**Key changes summarized:**
- `effectiveBg`, `effectiveFg`, `effectiveBorder` are computed inside `build()` using `context.sac` when disabled.
- `WidgetStateProperty.resolveWith` replaced with `WidgetStateProperty.all` since we resolve the disabled state ourselves (cleaner, avoids Material's built-in disabled behavior conflicting with ours).
- `_borderSide` still returns the variant's normal border; only overridden to neutral when disabled.
- Loading spinner color uses `effectiveFg` so it's muted when disabled.
- Icon colors use `effectiveFg` instead of raw `_foregroundColor`.
- `AnimatedOpacity` wrapper removed (I-4) — it was a no-op with `opacity: 1.0`.

- [ ] **Step 3: Add the `sac_colors.dart` import if not already present**

Check if `import '../../core/theme/sac_colors.dart'` (or the package-style import) exists in `sac_button.dart`. The file currently imports `app_colors.dart` but may not import `sac_colors.dart`. Add:

```dart
import 'package:sacdia_app/core/theme/sac_colors.dart';
```

- [ ] **Step 4: Run `flutter analyze` to verify**

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-app && flutter analyze lib/core/widgets/sac_button.dart
```

- [ ] **Step 5: Commit**

```bash
git add lib/core/widgets/sac_button.dart
git commit -m "fix: refactor SacButton disabled state to use theme tokens"
```

---

## Task 8: Integration — Classes (RequirementDetailView)

**Files:**
- Modify: `lib/features/classes/presentation/views/requirement_detail_view.dart`

- [ ] **Step 1: Read the current file to confirm the latest state**

Read: `lib/features/classes/presentation/views/requirement_detail_view.dart`

- [ ] **Step 2: Replace imports — remove old grid, add staging manager**

Remove:
```dart
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/requirement_evidence_grid.dart';
```

Add:
```dart
import '../../../../core/widgets/evidence_staging/evidence_staging_manager.dart';
import '../../../../core/widgets/evidence_staging/staged_file.dart';
```

Keep `image_picker` import only if `XFile` is still referenced transitively (it is, via the staging manager callback signature). Actually, `XFile` is re-exported by `image_picker`, and the staging manager uses it — but the import is inside the staging manager file, not here. Since the `onUpload` callback receives `XFile`, the parent needs it. **Keep `import 'package:image_picker/image_picker.dart';`** for the `XFile` type.

Remove `import 'package:file_picker/file_picker.dart';` — no longer used directly.

- [ ] **Step 3: Remove old state and methods from `_RequirementDetailViewState`**

Delete the following members:
- `final _picker = ImagePicker();`
- `bool _isUploading = false;`
- The entire `_pickImage()` method
- The entire `_pickPdf()` method
- The entire `_showImageSourceDialog()` method
- The entire `_showSubmitConfirmDialog()` method (the staging manager has its own)

Keep:
- `_liveRequirement()` — still needed to get live data
- `_buildFileNameWithIndex()`, `_sanitize()`, `_resolveModuleName()`, `_resolveUserInitials()` — used for `fileNameBuilder`
- `_confirmDelete()` — adapted for remote delete callback
- `_submit()` — simplified to just call the notifier
- `_showErrorSnackbar()` — still used

- [ ] **Step 4: Replace the grid and bottom bar in `build()`**

No `GlobalKey` needed (I-2 fix). The `EvidenceStagingManager` outputs both grid and action bar internally. Place it inside the Scaffold `body`, NOT `bottomNavigationBar`. Remove the `bottomNavigationBar` property entirely from the Scaffold.

In the `build()` method, replace the entire "Archivos de evidencia" section (the header, the empty state, the grid, and the spacing) with:

```dart
// Archivos de evidencia
Padding(
  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
  child: Text(
    'Archivos de evidencia',
    style: Theme.of(context)
        .textTheme
        .titleSmall
        ?.copyWith(
          fontWeight: FontWeight.w700,
          color: c.text,
        ),
  ),
),

// I-2: EvidenceStagingManager goes inside the body, NOT bottomNavigationBar.
// It manages its own action bar internally — no GlobalKey needed.
// Wrap it in Expanded if it's inside a Column, so it fills available space.
Expanded(
  child: EvidenceStagingManager(
    existingFiles: requirement.files
        .map(StagedFile.fromRequirementEvidence)
        .toList(),
    maxFiles: requirement.maxFiles,
    isLoading: notifierState.isLoading,
    // C-1: Pass onProgress through to the notifier so Dio reports progress.
    // C-2: skipInvalidation prevents per-file provider refresh mid-batch.
    // I-6: Throw on false so the staging manager catches the error.
    onUpload: (xFile, mimeType, onProgress) async {
      final success = await ref
          .read(requirementNotifierProvider(widget.classId).notifier)
          .uploadFile(
            requirementId: requirement.id,
            pickedFile: xFile,
            mimeType: mimeType,
            onProgress: onProgress,
            skipInvalidation: true,
          );
      if (!success) throw Exception('Upload failed');
    },
    onDeleteRemote: (fileId) async {
      await ref
          .read(requirementNotifierProvider(widget.classId).notifier)
          .deleteFile(
            requirementId: requirement.id,
            fileId: fileId,
          );
    },
    onSubmit: () async {
      final success = await ref
          .read(requirementNotifierProvider(widget.classId).notifier)
          .submit(requirement.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Requerimiento enviado a validación exitosamente'),
                ),
              ],
            ),
            backgroundColor: AppColors.secondary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context);
      }
    },
    fileNameBuilder: (originalName, index) =>
        _buildFileNameWithIndex(requirement, originalName, index),
    canModify: canModify,
  ),
),
```

Remove the old `_BottomActionBar` widget class entirely. Remove the `bottomNavigationBar` property from the Scaffold — the action bar is now built inside `EvidenceStagingManager` (I-2 fix).

- [ ] **Step 5: Remove the loading overlay logic that uses `_isUploading`**

Replace:
```dart
final isLoading = notifierState.isLoading || _isUploading;
```

With:
```dart
final isLoading = notifierState.isLoading;
```

The staging manager handles its own upload state internally.

- [ ] **Step 6: Remove the old `_submit()` method**

It is now replaced by the inline `onSubmit` callback.

- [ ] **Step 7: Remove the old `_confirmDelete()` method**

Remote file deletion is now handled inside `EvidenceStagingManager._deleteRemoteFile` → calls `onDeleteRemote` callback.

- [ ] **Step 8: Remove the file counter from the header Row**

The staging grid now shows its own counter below the grid. Remove:
```dart
const Spacer(),
if (canModify)
  Text(
    '${requirement.files.length} / ${requirement.maxFiles}',
    ...
  ),
```

- [ ] **Step 9: Add `PopScope` for navigate-away warning**

Add a `_hasUnsavedFiles` boolean field to `_RequirementDetailViewState` that the `EvidenceStagingManager` updates via a callback. Add `onLocalFilesChanged: (hasLocal) => setState(() => _hasUnsavedFiles = hasLocal)` to the manager constructor (this requires adding the callback to `EvidenceStagingManager` — see note below). Alternatively, since the manager is inside the same widget tree, the simpler approach is to track local files at the parent level by counting them from the `existingFiles` vs total:

Wrap the Scaffold (or its body) with `PopScope`:

```dart
return PopScope(
  canPop: !_hasUnsavedFiles,
  onPopInvokedWithResult: (didPop, result) async {
    if (didPop) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Archivos sin enviar'),
        content: const Text(
          'Tenés archivos sin enviar. ¿Seguro que querés salir?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Quedarme'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      Navigator.pop(context);
    }
  },
  child: Scaffold(
    // ... existing scaffold content
  ),
);
```

- [ ] **Step 10: Delete the old `_BottomActionBar` private widget class from the file**

Remove the entire `class _BottomActionBar extends StatelessWidget { ... }` block.

- [ ] **Step 11: Run `flutter analyze`**

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-app && flutter analyze lib/features/classes/presentation/views/requirement_detail_view.dart
```

- [ ] **Step 12: Commit**

```bash
git add lib/features/classes/presentation/views/requirement_detail_view.dart
git commit -m "feat: integrate EvidenceStagingManager into RequirementDetailView"
```

---

## Task 9: Integration — Evidence Folders (EvidenceSectionDetailView)

**Files:**
- Modify: `lib/features/evidence_folder/presentation/views/evidence_section_detail_view.dart`

- [ ] **Step 1: Read the current file to confirm the latest state**

Read: `lib/features/evidence_folder/presentation/views/evidence_section_detail_view.dart`

- [ ] **Step 2: Replace imports — remove old grid, add staging manager**

Remove:
```dart
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/evidence_file_grid.dart';
```

Add:
```dart
import '../../../../core/widgets/evidence_staging/evidence_staging_manager.dart';
import '../../../../core/widgets/evidence_staging/staged_file.dart';
```

Keep `import 'package:image_picker/image_picker.dart';` for `XFile` type if still needed by the callback. Actually, check if `XFile` is needed — the `onUpload` callback receives `XFile`. Since `XFile` comes from `image_picker`, keep the import.

Remove `import 'package:file_picker/file_picker.dart';`.

- [ ] **Step 3: Remove old state and methods from `_EvidenceSectionDetailViewState`**

Delete:
- `final _picker = ImagePicker();`
- `bool _isUploading = false;`
- `bool get _canModify =>` (keep a local variable in build instead)
- `_pickImage()`, `_pickPdf()`, `_submit()`, `_confirmDelete()`
- `_showImageSourceDialog()`, `_showSubmitConfirmDialog()`

Keep:
- `_showErrorSnackbar()`

- [ ] **Step 4: Replace the grid and bottom bar in `build()`, add `PopScope`**

No `GlobalKey` needed (I-2 fix). Same approach as Task 8 — `EvidenceStagingManager` goes inside the Scaffold `body`, not `bottomNavigationBar`. Remove `bottomNavigationBar` entirely.

Follow the same pattern as Task 8 but with evidence folder entities and notifier:

```dart
// Map files
existingFiles: widget.section.files
    .map(StagedFile.fromEvidenceFile)
    .toList(),
maxFiles: widget.section.maxFiles,
// C-1: Pass onProgress through to the notifier so Dio reports progress.
// C-2: skipInvalidation prevents per-file provider refresh mid-batch.
// I-6: Throw on false so the staging manager catches the error.
onUpload: (xFile, mimeType, onProgress) async {
  final success = await ref
      .read(evidenceSectionNotifierProvider(widget.clubSectionId).notifier)
      .uploadFile(
        sectionId: widget.section.id,
        pickedFile: xFile,
        mimeType: mimeType,
        onProgress: onProgress,
        skipInvalidation: true,
      );
  if (!success) throw Exception('Upload failed');
},
onDeleteRemote: (fileId) async {
  await ref
      .read(evidenceSectionNotifierProvider(widget.clubSectionId).notifier)
      .deleteFile(
        sectionId: widget.section.id,
        fileId: fileId,
      );
},
onSubmit: () async {
  final success = await ref
      .read(evidenceSectionNotifierProvider(widget.clubSectionId).notifier)
      .submit(widget.section.id);
  if (success && mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded,
                color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Sección enviada a validación exitosamente'),
          ],
        ),
        backgroundColor: AppColors.secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
      ),
    );
    Navigator.pop(context);
  }
},
```

For `fileNameBuilder`, create a simple builder in this view since it doesn't have the same module-based naming as classes:

```dart
fileNameBuilder: (originalName, index) {
  final ext = originalName.contains('.')
      ? originalName.split('.').last.toLowerCase()
      : 'bin';
  final sectionName = widget.section.name
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  final truncated = sectionName.substring(
      0, sectionName.length.clamp(0, 30));
  return 'evidencia_${index}_$truncated.$ext';
},
```

- [ ] **Step 5: Replace `_canModify` getter with local variable in build, wrap with `PopScope`**

Same `PopScope` pattern as Task 8.

```dart
final canModify =
    widget.section.status == EvidenceSectionStatus.pendiente &&
    widget.folderIsOpen;
```

- [ ] **Step 6: Remove the file counter from the header Row**

Same as Task 8 — the staging grid shows its own counter.

- [ ] **Step 7: Remove old `_BottomActionBar`, `_EmptyFiles` private widget classes**

- [ ] **Step 8: Remove old `_submit()` method**

- [ ] **Step 9: Run `flutter analyze`**

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-app && flutter analyze lib/features/evidence_folder/presentation/views/evidence_section_detail_view.dart
```

- [ ] **Step 10: Commit**

```bash
git add lib/features/evidence_folder/presentation/views/evidence_section_detail_view.dart
git commit -m "feat: integrate EvidenceStagingManager into EvidenceSectionDetailView"
```

---

## Task 10: Cleanup — Delete Deprecated Grid Widgets

**Files:**
- Delete: `lib/features/classes/presentation/widgets/requirement_evidence_grid.dart`
- Delete: `lib/features/evidence_folder/presentation/widgets/evidence_file_grid.dart`

- [ ] **Step 1: Verify no other files import the deprecated grids**

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-app && rg "requirement_evidence_grid" lib/ --files-with-matches
cd /Users/abner/Documents/development/sacdia/sacdia-app && rg "evidence_file_grid" lib/ --files-with-matches
```

If any files besides the two detail views still import them, update those imports first.

- [ ] **Step 2: Delete the deprecated grid files**

```bash
rm lib/features/classes/presentation/widgets/requirement_evidence_grid.dart
rm lib/features/evidence_folder/presentation/widgets/evidence_file_grid.dart
```

- [ ] **Step 3: Remove any dead imports from the detail views**

Check both detail views for any remaining imports of the old grids. They should already be removed in Tasks 8 and 9, but verify:

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-app && rg "requirement_evidence_grid\|evidence_file_grid" lib/ --files-with-matches
```

- [ ] **Step 4: Remove dead code from detail views**

Check both detail views for any remaining methods that are no longer called:
- Any leftover `_picker` references
- Any leftover `_isUploading` references
- Any unused private widget classes

- [ ] **Step 5: Run full `flutter analyze` across the entire app**

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-app && flutter analyze
```

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "refactor: delete deprecated evidence grid widgets and dead code"
```

---

## Post-Implementation Verification

After all tasks are complete:

- [ ] Run `flutter analyze` with zero warnings/errors
- [ ] Manual test: RequirementDetailView — add images (camera + gallery multi), add PDFs, verify grid shows local files with dashed border and "Nuevo" badge, remove a local file, submit and verify progress sheet
- [ ] Manual test: EvidenceSectionDetailView — same flow
- [ ] Manual test: Navigate back with local files staged — verify confirmation dialog
- [ ] Manual test: Disabled buttons — verify neutral appearance (no red border when disabled)
- [ ] Manual test: All files remote, submit without new uploads — verify it skips upload phase
- [ ] Manual test: Exceed file limit — verify red border on excess tiles and disabled submit button
