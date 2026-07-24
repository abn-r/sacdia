# Compact Member Tabs and Cards Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Reducir la altura del selector de pestañas y de las tarjetas del listado de Miembros sin cambiar su comportamiento o ancho.

**Architecture:** `MembersView` definirá ambas pestañas con una altura explícita de 40 dp y un padding de `TabBar` de 2 dp. `MemberCard` conservará el mismo layout y reducirá exclusivamente su padding vertical a 12 dp; una key semántica de prueba permitirá medir su contenedor de contenido.

**Tech Stack:** Flutter, Dart, Riverpod, easy_localization, flutter_test.

---

## Restricciones de ejecución

- Trabajar directamente en `sacdia-app` sobre `development`.
- Aplicar TDD: tests rojos antes de modificar producción.
- No ejecutar `flutter build`, `flutter run` ni crear una rama alternativa.
- No cambiar ancho, labels, badge, avatar, acciones, fuentes, colores ni datos.

### Task 1: Escribir los tests rojos de dimensiones

**Files:**
- Modify: `sacdia-app/test/features/members/presentation/widgets/member_card_test.dart`
- Create: `sacdia-app/test/features/members/presentation/views/members_view_tab_bar_test.dart`
- Read: `sacdia-app/lib/features/members/presentation/views/members_view.dart:105-161`
- Read: `sacdia-app/lib/features/members/presentation/widgets/member_card.dart:34-42`

**Step 1: Especificar la altura de la tarjeta**

Extender el helper actual de `MemberCard` y añadir:

```dart
expect(
  tester.getSize(find.byKey(const ValueKey('member-card-content'))).height,
  74,
);
```

La tarjeta fixture debe mantener avatar fallback y una clase para cubrir el
contenido real de la línea de clase.

**Step 2: Especificar las pestañas compactas**

Crear un host de `MembersView` con `ProviderScope`, fake de autenticación,
`MembersNotifier` vacío y `ClubContext` válido. Inicializar
`EasyLocalization` con el asset loader de pruebas existente. Tras el pump:

```dart
final tabBar = tester.widget<TabBar>(find.byType(TabBar));
expect(tabBar.padding, const EdgeInsets.all(2));
expect(
  tester.widgetList<Tab>(find.byType(Tab)).map((tab) => tab.height),
  everyElement(40),
);
```

**Step 3: Ejecutar RED**

Run:

```bash
cd sacdia-app
flutter test test/features/members/presentation/widgets/member_card_test.dart \
  test/features/members/presentation/views/members_view_tab_bar_test.dart
```

Expected: FAIL porque no existe la key de contenido, las pestañas no tienen
altura explícita y el padding actual es 4 dp.

### Task 2: Compactar tarjeta y selector de pestañas

**Files:**
- Modify: `sacdia-app/lib/features/members/presentation/widgets/member_card.dart:34-42`
- Modify: `sacdia-app/lib/features/members/presentation/views/members_view.dart:117-158`
- Test: `sacdia-app/test/features/members/presentation/widgets/member_card_test.dart`
- Test: `sacdia-app/test/features/members/presentation/views/members_view_tab_bar_test.dart`

**Step 1: Reducir el padding vertical de `MemberCard`**

Asignar `key: const ValueKey('member-card-content')` al `Container` de
contenido y sustituir:

```dart
padding: const EdgeInsets.all(14),
```

por:

```dart
padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
```

**Step 2: Reducir la altura de las pestañas**

Cambiar el padding de `TabBar` a:

```dart
padding: const EdgeInsets.all(2),
```

Definir ambos widgets como `Tab(height: 40, ...)`, conservando los children,
texto y badge actuales.

**Step 3: Ejecutar GREEN, formatear y analizar**

Run:

```bash
cd sacdia-app
dart format lib/features/members/presentation/widgets/member_card.dart \
  lib/features/members/presentation/views/members_view.dart \
  test/features/members/presentation/widgets/member_card_test.dart \
  test/features/members/presentation/views/members_view_tab_bar_test.dart
flutter test test/features/members/presentation/widgets/member_card_test.dart \
  test/features/members/presentation/views/members_view_tab_bar_test.dart
flutter analyze lib/features/members/presentation/widgets/member_card.dart \
  lib/features/members/presentation/views/members_view.dart \
  test/features/members/presentation/widgets/member_card_test.dart \
  test/features/members/presentation/views/members_view_tab_bar_test.dart
git diff --check
```

Expected: tests y analyzer sin errores, sin ejecutar builds.

**Step 4: Commit**

```bash
cd sacdia-app
git add lib/features/members/presentation/widgets/member_card.dart \
  lib/features/members/presentation/views/members_view.dart \
  test/features/members/presentation/widgets/member_card_test.dart \
  test/features/members/presentation/views/members_view_tab_bar_test.dart
git commit -m "style: compact member tabs and cards"
```
