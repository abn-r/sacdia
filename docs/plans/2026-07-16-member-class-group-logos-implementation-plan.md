# Member Class Group Logos Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Mostrar el logo local de cada clase a la izquierda de los encabezados de grupos en la lista de miembros de `sacdia-app`.

**Architecture:** Un widget de presentación reutilizable resolverá los assets mediante `AppColors.classLogoAsset`. `MembersView` lo usará en lugar de su encabezado privado actual; el provider y los datos de miembros no cambian.

**Tech Stack:** Flutter, Dart, flutter_test, assets locales PNG.

---

## Restricciones de ejecución

- Trabajar directamente en `sacdia-app` sobre `development`.
- Aplicar TDD estricto; no escribir producción antes del test rojo.
- No ejecutar `flutter build` ni otros builds.
- No modificar backend, providers, contratos ni assets existentes.
- `Sin clase` no debe mostrar logo.

### Task 1: Escribir el test rojo del encabezado de grupo

**Files:**
- Create: `sacdia-app/test/features/members/presentation/widgets/member_class_group_header_test.dart`
- Read: `sacdia-app/lib/core/theme/app_colors.dart:277-296`

**Step 1: Especificar una clase con logo**

Renderizar `MemberClassGroupHeader(label: 'Amigo', count: 5)` dentro de
`MaterialApp` y comprobar:

```dart
expect(find.byKey(const ValueKey('member-class-logo-Amigo')), findsOneWidget);
expect(find.text('AMIGO'), findsOneWidget);
expect(find.text('5'), findsOneWidget);
```

Obtener el `Image` del logo y verificar que usa
`assets/img/logos-clases/CQ-01.png`.

**Step 2: Especificar el grupo sin clase**

Renderizar `MemberClassGroupHeader(label: 'Sin clase', count: 1)` y comprobar
que no existe una key `member-class-logo-Sin clase`, mientras el texto y el
conteo siguen visibles.

**Step 3: Ejecutar RED**

Run:

```bash
cd sacdia-app
flutter test test/features/members/presentation/widgets/member_class_group_header_test.dart
```

Expected: FAIL porque `MemberClassGroupHeader` aún no existe.

### Task 2: Implementar el encabezado e integrarlo

**Files:**
- Create: `sacdia-app/lib/features/members/presentation/widgets/member_class_group_header.dart`
- Modify: `sacdia-app/lib/features/members/presentation/views/members_view.dart:288-292,561-604`
- Test: `sacdia-app/test/features/members/presentation/widgets/member_class_group_header_test.dart`

**Step 1: Implementar `MemberClassGroupHeader`**

Resolver el asset:

```dart
final logoAsset = AppColors.classLogoAsset(label);
```

Cuando exista, renderizarlo a la izquierda en 24 × 24 dp con:

```dart
Image.asset(
  logoAsset,
  key: ValueKey('member-class-logo-$label'),
  width: 24,
  height: 24,
  fit: BoxFit.contain,
  excludeFromSemantics: true,
)
```

Conservar tipografía, color, `letterSpacing` y badge de conteo del encabezado
actual. Si el asset es `null`, no agregar logo ni su espacio horizontal.

**Step 2: Integrar en `MembersView`**

Importar el widget nuevo y reemplazar `_ClassGroupHeader` en el `ListView`
virtualizado. Eliminar la clase privada reemplazada, sin modificar el cálculo
de índices ni el provider `membersByClassProvider`.

**Step 3: Ejecutar GREEN y analizar**

Run:

```bash
cd sacdia-app
dart format lib/features/members/presentation/widgets/member_class_group_header.dart \
  lib/features/members/presentation/views/members_view.dart \
  test/features/members/presentation/widgets/member_class_group_header_test.dart
flutter test test/features/members/presentation/widgets/member_class_group_header_test.dart
flutter analyze lib/features/members/presentation/widgets/member_class_group_header.dart \
  lib/features/members/presentation/views/members_view.dart \
  test/features/members/presentation/widgets/member_class_group_header_test.dart
```

Expected: test y analyzer sin errores, sin ejecutar builds.

**Step 4: Commit**

```bash
cd sacdia-app
git add lib/features/members test/features/members
git commit -m "feat: add class logos to member groups"
```
