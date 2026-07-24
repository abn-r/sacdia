# Fixed Input Icon Slots Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Fijar el slot de los iconos de entrada en 48 × 48 dp y evitar que los buscadores u otros campos de `sacdia-app` adopten dimensiones variables de su contenedor.

**Architecture:** Un widget de infraestructura encapsulará el glifo HugeIcons centrado y la constraint del slot. Los campos base usarán ese widget automáticamente; los `TextField` que construyen su `InputDecoration` localmente adoptarán el mismo patrón. El tamaño visual del glifo seguirá siendo explícito por uso.

**Tech Stack:** Flutter, Dart, HugeIcons, flutter_test.

---

## Restricciones de ejecución

- Trabajar únicamente en `sacdia-app` sobre la rama `development`.
- Aplicar TDD: ninguna modificación de producción antes de ver fallar su test.
- No ejecutar `flutter build` ni otro build.
- No modificar backend, contratos, providers, datos o navegación.
- No incluir archivos preexistentes ajenos en ningún commit.

### Task 1: Especificar el slot fijo con un test rojo

**Files:**
- Create: `sacdia-app/test/core/widgets/fixed_input_icon_slot_test.dart`
- Read: `sacdia-app/test/features/evidence_folder/evidence_folder_view_test.dart:211-229`

**Step 1: Escribir el widget test**

Renderizar un `TextField` cuya decoración use la nueva API esperada:

```dart
decoration: const InputDecoration(
  prefixIconConstraints: FixedInputIconSlot.constraints,
  prefixIcon: FixedInputIconSlot(
    icon: HugeIcons.strokeRoundedSearch01,
    color: Colors.black,
  ),
),
```

Esperar que el widget con key `fixed-input-icon-slot` mida `Size(20, 20)` y
que `prefixIconConstraints` tenga mínimo y máximo de 48 tanto en ancho como
en alto.

**Step 2: Ejecutar el test para comprobar RED**

Run:

```bash
cd sacdia-app
flutter test test/core/widgets/fixed_input_icon_slot_test.dart
```

Expected: FAIL porque `FixedInputIconSlot` aún no existe.

### Task 2: Implementar el componente y migrar los campos base

**Files:**
- Create: `sacdia-app/lib/core/widgets/fixed_input_icon_slot.dart`
- Modify: `sacdia-app/lib/core/widgets/sac_text_field.dart:174-180,217-232`
- Modify: `sacdia-app/lib/core/widgets/sac_dropdown_field.dart:147-151,183-196`
- Modify: `sacdia-app/lib/core/widgets/custom_text_field.dart:167-181,200-210`
- Modify: `sacdia-app/lib/features/auth/presentation/widgets/auth_text_field.dart:35-58`
- Test: `sacdia-app/test/core/widgets/fixed_input_icon_slot_test.dart`

**Step 1: Implementar el mínimo componente**

Crear `FixedInputIconSlot` con:

```dart
static const constraints = BoxConstraints.tightFor(width: 48, height: 48);
```

Su `build` debe devolver un `Center` con un `SizedBox` de `iconSize` (20 por
defecto), key `fixed-input-icon-slot`, y un `HugeIcon` del mismo tamaño.

**Step 2: Aplicar el componente a campos base**

Reemplazar los prefijos manuales en `SacTextField`, `SacDropdownField` y
`CustomTextField` por `FixedInputIconSlot`, y sustituir sus constraints de
mínimos por `FixedInputIconSlot.constraints`. En `AuthTextField`, aplicar el
mismo prefijo y constraint explícita.

**Step 3: Ejecutar el test para comprobar GREEN**

Run:

```bash
cd sacdia-app
flutter test test/core/widgets/fixed_input_icon_slot_test.dart
```

Expected: PASS.

### Task 3: Migrar todos los buscadores directos

**Files:**
- Modify: `sacdia-app/lib/features/camporees/presentation/views/camporee_register_member_view.dart:557-587`
- Modify: `sacdia-app/lib/features/coordinator/presentation/views/coordinator_clubs_list_view.dart:182-212`
- Modify: `sacdia-app/lib/features/enrollment/presentation/views/enrollment_form_view.dart:1661-1688`
- Modify: `sacdia-app/lib/features/honors/presentation/views/honors_catalog_view.dart:307-350`
- Modify: `sacdia-app/lib/features/insurance/presentation/views/insurance_view.dart:306-353`
- Modify: `sacdia-app/lib/features/inventory/presentation/widgets/inventory_summary_header.dart:328-375`
- Modify: `sacdia-app/lib/features/materials/presentation/views/catalog_view.dart:115-131`
- Modify: `sacdia-app/lib/features/members/presentation/views/members_view.dart:786-810`
- Modify: `sacdia-app/lib/features/members/presentation/widgets/members_filter_bar.dart:45-78`
- Modify: `sacdia-app/lib/features/post_registration/presentation/views/add_edit_contact_view.dart:579-609`
- Modify: `sacdia-app/lib/features/post_registration/presentation/views/allergies_selection_view.dart:650-690`
- Modify: `sacdia-app/lib/features/post_registration/presentation/views/diseases_selection_view.dart:633-673`
- Modify: `sacdia-app/lib/features/post_registration/presentation/views/medicines_selection_view.dart:630-670`
- Modify: `sacdia-app/lib/features/post_registration/presentation/widgets/bottom_sheet_picker.dart:304-340`
- Modify: `sacdia-app/lib/features/post_registration/presentation/widgets/searchable_selection_list.dart:140-163`
- Modify: `sacdia-app/lib/features/support/presentation/views/faq_view.dart:250-296`
- Modify: `sacdia-app/lib/features/units/presentation/views/unit_form_sheet.dart:806-844,1060-1097`

**Step 1: Reemplazar cada `prefixIcon` de búsqueda**

En cada decoración, agregar:

```dart
prefixIconConstraints: FixedInputIconSlot.constraints,
prefixIcon: FixedInputIconSlot(
  icon: HugeIcons.strokeRoundedSearch01,
  color: /* color existente */,
  iconSize: /* tamaño existente o 20 */,
),
```

Conservar textos, callbacks, bordes, rellenos y comportamiento de limpieza.
Usar `iconSize: 18` o `22` solo donde esa densidad ya exista. No modificar los
buscadores que ya usan una fila con `HugeIcon` explícitamente acotado ni
`EvidenceSectionSearchField`, que ya implementa el patrón de referencia.

**Step 2: Ejecutar los tests de las áreas de referencia**

Run:

```bash
cd sacdia-app
flutter test \
  test/core/widgets/fixed_input_icon_slot_test.dart \
  test/features/evidence_folder/evidence_folder_view_test.dart \
  test/features/coordinator/presentation/views/coordinator_clubs_list_view_test.dart
```

Expected: PASS.

### Task 4: Corregir los demás iconos de entrada y verificar el inventario

**Files:**
- Modify: `sacdia-app/lib/features/camporees/presentation/views/camporee_enroll_club_view.dart`
- Modify: `sacdia-app/lib/features/camporees/presentation/views/camporee_payments_view.dart`
- Modify: `sacdia-app/lib/features/post_registration/presentation/views/legal_representative_view.dart`
- Read: `sacdia-app/lib/features/evidence_folder/presentation/widgets/evidence_folder_overview.dart`

**Step 1: Aplicar el mismo slot a los prefijos no relacionados con búsqueda**

Migrar únicamente los `InputDecoration.prefixIcon` directos que no tienen una
constraint fija. Mantener sin cambios los iconos de estados vacíos, iconos de
listas y botones con áreas táctiles intencionales.

**Step 2: Comprobar estáticamente la cobertura**

Run:

```bash
cd sacdia-app
grep -RInE --include='*.dart' 'prefixIcon:' lib
```

Revisar que cada uso directo tenga `FixedInputIconSlot.constraints`, que los
campos base lo proporcionen internamente o que sea el componente de Evidencias
ya probado. Documentar los usos exentos y su motivo en el reporte final.

**Step 3: Formatear y ejecutar la verificación final**

Run:

```bash
cd sacdia-app
dart format lib/core/widgets/fixed_input_icon_slot.dart \
  lib/core/widgets/sac_text_field.dart \
  lib/core/widgets/sac_dropdown_field.dart \
  lib/core/widgets/custom_text_field.dart \
  lib/features/auth/presentation/widgets/auth_text_field.dart \
  test/core/widgets/fixed_input_icon_slot_test.dart
flutter test test/core/widgets/fixed_input_icon_slot_test.dart \
  test/features/evidence_folder/evidence_folder_view_test.dart \
  test/features/coordinator/presentation/views/coordinator_clubs_list_view_test.dart
flutter analyze lib/core/widgets/fixed_input_icon_slot.dart \
  lib/core/widgets/sac_text_field.dart \
  lib/core/widgets/sac_dropdown_field.dart
```

Expected: formato aplicado, tests y analyze sin errores; no ejecutar build.

**Step 4: Commit**

```bash
cd sacdia-app
git add lib test
git commit -m "fix: constrain input icon slots"
```
