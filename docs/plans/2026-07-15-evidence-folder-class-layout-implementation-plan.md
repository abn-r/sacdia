# Evidence Folder Class Layout Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Rediseñar la Carpeta Anual de Evidencias de Flutter con la jerarquía visual completa de la pantalla de Clase, conservando los contratos y comportamientos actuales.

**Architecture:** La pantalla seguirá consumiendo `EvidenceFolder` mediante Riverpod y derivará búsqueda y conteos localmente. Los componentes visuales nuevos serán específicos de `evidence_folder`, compartirán tokens de `AppColors`/`SacColors` con Classes y mantendrán `SectionCard` como frontera de interacción de cada sección.

**Tech Stack:** Flutter, Dart, Riverpod, EasyLocalization, HugeIcons, flutter_test.

---

## Restricciones de ejecución

- Aplicar TDD estricto: cada comportamiento nuevo debe fallar primero en un widget test.
- No modificar endpoints, DTOs, entidades ni providers remotos.
- No ejecutar `flutter build` ni ningún otro build.
- No incluir cambios preexistentes de otros repositorios o documentación en los commits.
- Usar conventional commits sin `Co-Authored-By` ni atribución de IA.

### Task 1: Especificar hero, conteos y búsqueda con widget tests

**Files:**
- Create: `sacdia-app/test/features/evidence_folder/evidence_folder_view_test.dart`
- Read: `sacdia-app/lib/features/evidence_folder/presentation/providers/evidence_folder_providers.dart`
- Read: `sacdia-app/lib/features/evidence_folder/domain/entities/evidence_folder.dart`
- Read: `sacdia-app/lib/features/evidence_folder/domain/entities/evidence_section.dart`

**Step 1: Crear el harness de la pantalla**

Crear una función `pumpEvidenceFolder` que renderice `EvidenceFolderView(clubSectionId: '2')` dentro de `ProviderScope` y sobrescriba:

```dart
evidenceFolderProvider('2').overrideWith((ref) async => folder)
```

Usar un fixture con cinco secciones, una por cada `EvidenceSectionStatus`, puntajes server-authoritative y descripciones distintas. Inicializar EasyLocalization con el mismo patrón de los widget tests existentes.

**Step 2: Escribir el test del resumen y estados**

El test debe esperar:

```dart
expect(find.byKey(const ValueKey('evidence-folder-hero')), findsOneWidget);
expect(find.text('62%'), findsOneWidget);
expect(find.byKey(const ValueKey('evidence-status-validated')), findsOneWidget);
expect(find.byKey(const ValueKey('evidence-status-preapproved')), findsOneWidget);
expect(find.byKey(const ValueKey('evidence-status-submitted')), findsOneWidget);
expect(find.byKey(const ValueKey('evidence-status-rejected')), findsOneWidget);
expect(find.byKey(const ValueKey('evidence-status-pending')), findsOneWidget);
```

Cada pill debe mostrar el conteo `1` del fixture.

**Step 3: Escribir los tests de búsqueda**

Agregar dos tests separados:

1. una consulta por nombre deja visible solo la sección coincidente;
2. una consulta por descripción funciona sin distinguir mayúsculas y muestra el estado sin resultados cuando no hay coincidencias.

Usar una key estable para el campo:

```dart
final search = find.byKey(const ValueKey('evidence-section-search'));
await tester.enterText(search, 'iglesia');
await tester.pump();
```

**Step 4: Ejecutar los tests para comprobar RED**

Run:

```bash
cd sacdia-app
flutter test test/features/evidence_folder/evidence_folder_view_test.dart
```

Expected: FAIL porque el hero, pills, buscador y keys todavía no existen.

**Step 5: Commit del test rojo**

```bash
git add test/features/evidence_folder/evidence_folder_view_test.dart
git commit -m "test: specify evidence folder overview"
```

### Task 2: Implementar el overview equivalente a Clase

**Files:**
- Create: `sacdia-app/lib/features/evidence_folder/presentation/widgets/evidence_folder_overview.dart`
- Modify: `sacdia-app/lib/features/evidence_folder/presentation/views/evidence_folder_view.dart:84-291`
- Test: `sacdia-app/test/features/evidence_folder/evidence_folder_view_test.dart`

**Step 1: Añadir estado local de búsqueda**

En `_FolderBodyState`, crear y liberar:

```dart
final _searchController = TextEditingController();
final _searchFocusNode = FocusNode();
String _query = '';

@override
void dispose() {
  _searchController.dispose();
  _searchFocusNode.dispose();
  super.dispose();
}
```

Derivar secciones sin mutar `folder.sections`:

```dart
List<EvidenceSection> _filteredSections(List<EvidenceSection> sections) {
  final query = _query.trim().toLowerCase();
  if (query.isEmpty) return sections;
  return sections.where((section) {
    final name = section.name.toLowerCase();
    final description = section.description?.toLowerCase() ?? '';
    return name.contains(query) || description.contains(query);
  }).toList(growable: false);
}
```

**Step 2: Crear `EvidenceFolderHero`**

El widget debe:

- usar `folder.completionRatio`, limitado a `0.0..1.0`;
- mostrar porcentaje entero con cifras tabulares;
- mostrar `folder.earnedPoints / folder.maxPoints`;
- dibujar un aro de progreso con icono de carpeta;
- comunicar el estado con texto e icono, no solo color;
- exponer `ValueKey('evidence-folder-hero')` y una etiqueta `Semantics` completa.

No copiar widgets privados de Classes. Reproducir composición y tokens con implementación propia.

**Step 3: Crear `EvidenceStatusPills`**

Contar estados directamente desde `folder.sections`. `preapprovedLf` debe tener una pill independiente; no usar `EvidenceFolder.submittedCount`, porque ese helper agrupa enviados y preaprobados.

Las keys son:

```text
evidence-status-validated
evidence-status-preapproved
evidence-status-submitted
evidence-status-rejected
evidence-status-pending
```

La fila debe ser horizontal, desplazable y mantener objetivos táctiles/semánticos suficientes.

**Step 4: Crear `EvidenceSectionSearchField` y estado vacío**

El campo recibe controller, focusNode, query, `onChanged` y `onClear`. La acción de limpiar debe ocupar al menos 48x48 dp. El estado vacío debe conservar el buscador visible y permitir cambiar la consulta.

**Step 5: Integrar el overview**

Reemplazar `_FolderHeaderCard` y `_ProgressSummaryRow` por:

```dart
EvidenceFolderHero(folder: folder),
EvidenceStatusPills(sections: folder.sections),
EvidenceSectionSearchField(...),
```

Mantener `FolderClosedBanner`, `_UnderEvaluationBanner`, app bar y refresh existentes.

**Step 6: Ejecutar los tests para comprobar GREEN**

Run:

```bash
cd sacdia-app
flutter test test/features/evidence_folder/evidence_folder_view_test.dart
```

Expected: PASS en los tests de hero, estados y búsqueda.

**Step 7: Commit**

```bash
git add lib/features/evidence_folder/presentation/views/evidence_folder_view.dart \
  lib/features/evidence_folder/presentation/widgets/evidence_folder_overview.dart \
  test/features/evidence_folder/evidence_folder_view_test.dart
git commit -m "feat: redesign evidence folder overview"
```

### Task 3: Especificar e implementar la lista compacta agrupada

**Files:**
- Modify: `sacdia-app/test/features/evidence_folder/evidence_folder_view_test.dart`
- Modify: `sacdia-app/lib/features/evidence_folder/presentation/views/evidence_folder_view.dart:259-286`
- Modify: `sacdia-app/lib/features/evidence_folder/presentation/widgets/section_card.dart:14-396`

**Step 1: Escribir tests de interacción de las filas**

Agregar tests independientes que verifiquen:

- existe una sola tarjeta agrupada con key `evidence-sections-card`;
- cada fila tiene key `evidence-section-<id>`;
- la fila muestra nombre, estado, puntos y relación de archivos;
- tocar la fila navega a `EvidenceSectionDetailView`;
- una sección pendiente con archivos muestra `Enviar a validación`;
- una carpeta cerrada no muestra la acción de envío;
- tocar la acción abre el diálogo de confirmación sin abrir el detalle.

**Step 2: Ejecutar los tests para comprobar RED**

Run:

```bash
cd sacdia-app
flutter test test/features/evidence_folder/evidence_folder_view_test.dart
```

Expected: FAIL porque la lista todavía usa tarjetas independientes.

**Step 3: Convertir `SectionCard` en una fila compacta**

La fila debe usar `Material` + `InkWell`, no `GestureDetector`, para ofrecer feedback táctil. Debe incluir:

- indicador circular semántico de estado/progreso;
- título y descripción con overflow controlado;
- label del estado;
- puntos y archivos;
- trazabilidad resumida cuando exista;
- chevron;
- botón de envío con target mínimo de 48 dp.

El callback del botón debe ejecutarse de forma independiente del `onTap` de la fila.

**Step 4: Agrupar filas en la vista**

Sustituir el `SliverList` de tarjetas con margen por un `SliverToBoxAdapter` que renderice un contenedor único:

```dart
Container(
  key: const ValueKey('evidence-sections-card'),
  decoration: ...,
  child: Column(
    children: [
      for (final section in filteredSections) ...[
        SectionCard(...),
        if (section != filteredSections.last) const Divider(height: 1),
      ],
    ],
  ),
)
```

No usar comparación de objetos para detectar la última fila si hay riesgo de duplicados; preferir un loop por índice.

**Step 5: Ejecutar los tests para comprobar GREEN**

Run:

```bash
cd sacdia-app
flutter test test/features/evidence_folder/evidence_folder_view_test.dart
```

Expected: PASS en navegación, renderizado y visibilidad de acciones.

**Step 6: Commit**

```bash
git add lib/features/evidence_folder/presentation/views/evidence_folder_view.dart \
  lib/features/evidence_folder/presentation/widgets/section_card.dart \
  test/features/evidence_folder/evidence_folder_view_test.dart
git commit -m "feat: compact evidence section list"
```

### Task 4: Alinear skeleton, traducciones y documentación canónica

**Files:**
- Modify: `sacdia-app/lib/features/evidence_folder/presentation/widgets/evidence_folder_loading_skeleton.dart`
- Modify: `sacdia-app/assets/translations/es.json`
- Modify: `sacdia-app/assets/translations/en.json`
- Modify: `sacdia-app/assets/translations/fr.json`
- Modify: `sacdia-app/assets/translations/pt-BR.json`
- Modify: `docs/features/annual-folders-scoring.md:34-41`

**Step 1: Añadir traducciones equivalentes**

Agregar bajo `evidence_folder` las keys necesarias para:

```json
{
  "overview_label": "{name} · Avance",
  "score_summary": "{earned} / {max} pts",
  "search_hint": "Buscar sección de evidencia…",
  "no_results_title": "Sin coincidencias",
  "no_results_body": "Intenta con otro nombre o descripción.",
  "sections_overline": "Secciones de evidencia"
}
```

Ampliar `stats` con `preapproved` y `rejected`. Traducir con el mismo significado en los cuatro locales; no copiar español en los demás archivos.

**Step 2: Validar JSON**

Run:

```bash
cd sacdia-app
python3 -m json.tool assets/translations/es.json >/dev/null
python3 -m json.tool assets/translations/en.json >/dev/null
python3 -m json.tool assets/translations/fr.json >/dev/null
python3 -m json.tool assets/translations/pt-BR.json >/dev/null
```

Expected: cuatro comandos con exit code 0.

**Step 3: Actualizar el loading skeleton**

Reproducir la geometría general del nuevo layout:

- bloque hero;
- fila de pills;
- buscador;
- una tarjeta agrupada con filas compactas.

No introducir animaciones nuevas ni lógica de negocio.

**Step 4: Actualizar documentación canónica**

En la sección App de `annual-folders-scoring.md`, documentar que la vista móvil muestra resumen global, estados independientes, búsqueda local y filas compactas, preservando los estados server-authoritative.

**Step 5: Ejecutar el test focalizado**

Run:

```bash
cd sacdia-app
flutter test test/features/evidence_folder/evidence_folder_view_test.dart
```

Expected: PASS.

**Step 6: Commit por repositorio**

En `sacdia-app`:

```bash
git add lib/features/evidence_folder/presentation/widgets/evidence_folder_loading_skeleton.dart \
  assets/translations/es.json assets/translations/en.json \
  assets/translations/fr.json assets/translations/pt-BR.json
git commit -m "feat: polish evidence folder loading states"
```

En el workspace raíz:

```bash
git add docs/features/annual-folders-scoring.md
git commit -m "docs: document evidence folder mobile layout"
```

### Task 5: Verificación final sin build

**Files:**
- Verify: todos los archivos modificados en Tasks 1-4

**Step 1: Formatear Dart**

Run:

```bash
cd sacdia-app
dart format \
  lib/features/evidence_folder/presentation/views/evidence_folder_view.dart \
  lib/features/evidence_folder/presentation/widgets/evidence_folder_overview.dart \
  lib/features/evidence_folder/presentation/widgets/section_card.dart \
  lib/features/evidence_folder/presentation/widgets/evidence_folder_loading_skeleton.dart \
  test/features/evidence_folder/evidence_folder_view_test.dart
```

Expected: exit code 0.

**Step 2: Ejecutar suite focalizada del módulo**

Run:

```bash
cd sacdia-app
flutter test test/features/evidence_folder
```

Expected: todos los tests pasan, cero fallos.

**Step 3: Ejecutar análisis estático**

Run:

```bash
cd sacdia-app
flutter analyze
```

Expected: exit code 0 sin errores. No sustituir este comando por un build.

**Step 4: Revisar el diff**

Run:

```bash
git -C sacdia-app diff --check
git diff --check
git -C sacdia-app status --short
git status --short
```

Expected: sin whitespace errors; solo cambios esperados y cualquier modificación preexistente del usuario claramente separada.

**Step 5: Validación visual manual**

Con una sesión Flutter ya existente, usar hot reload si está disponible y validar en viewport móvil:

- escalado de texto;
- scroll horizontal de pills;
- búsqueda y limpieza;
- lista con descripciones largas;
- targets táctiles;
- carpeta abierta, cerrada y en evaluación.

No iniciar un build para esta validación.
