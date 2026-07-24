# Member Class ID Order Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Ordenar los grupos de la lista de miembros por `currentClassId` ascendente y conservar `Sin clase` al final.

**Architecture:** Una función pura y pública agrupará miembros por el nombre visible de clase y conservará el ID del grupo para ordenar. `membersByClassProvider` seguirá resolviendo filtros y traducción, delegando únicamente esta transformación; el mapa manual por nombres será eliminado.

**Tech Stack:** Flutter, Dart, Riverpod, flutter_test.

---

## Restricciones de ejecución

- Trabajar directamente en `sacdia-app` sobre `development`.
- Aplicar TDD: test rojo antes de producción.
- No ejecutar `flutter build`, `flutter run` ni crear ramas alternativas.
- No cambiar entidades, modelo API, filtros ni orden de miembros dentro de cada grupo.

### Task 1: Escribir la prueba roja del agrupamiento ordenado

**Files:**
- Create: `sacdia-app/test/features/members/presentation/providers/members_by_class_provider_test.dart`
- Read: `sacdia-app/lib/features/members/domain/entities/club_member.dart`
- Read: `sacdia-app/lib/features/members/presentation/providers/members_providers.dart:391-430`

**Step 1: Crear miembros fixture en orden arbitrario**

Crear una función `_member` con `userId`, `name`, `currentClass` y
`currentClassId`. Preparar una lista donde las clases aparezcan en este orden
de entrada: `Explorador` ID 12, `Amigo` ID 2, `Sin ID` sin ID, `Guía` ID 6 y
un miembro sin clase.

**Step 2: Especificar el orden por ID**

Invocar `groupMembersByClass(members, noClassLabel: 'Sin clase')` y verificar:

```dart
expect(
  grouped.keys,
  orderedEquals(['Amigo', 'Guía', 'Explorador', 'Sin ID', 'Sin clase']),
);
expect(grouped['Amigo']!.single.userId, 'amigo-1');
```

Agregar un segundo miembro `Amigo` para comprobar que la función conserva los
miembros del mismo grupo sin reordenarlos internamente.

**Step 3: Ejecutar RED**

Run:

```bash
cd sacdia-app
flutter test test/features/members/presentation/providers/members_by_class_provider_test.dart
```

Expected: FAIL porque `groupMembersByClass` aún no existe.

### Task 2: Extraer el agrupamiento y ordenar por ID

**Files:**
- Modify: `sacdia-app/lib/features/members/presentation/providers/members_providers.dart:391-430`
- Test: `sacdia-app/test/features/members/presentation/providers/members_by_class_provider_test.dart`

**Step 1: Crear `groupMembersByClass`**

Agregar una función pública con la firma:

```dart
Map<String, List<ClubMember>> groupMembersByClass(
  List<ClubMember> members, {
  required String noClassLabel,
})
```

La función debe agrupar por `member.currentClass ?? noClassLabel`, registrar
el primer ID no nulo de cada clase y devolver un nuevo mapa de inserción en
orden.

**Step 2: Definir comparador determinista**

En el comparador de grupos:

1. `noClassLabel` siempre va al final.
2. Dos IDs no nulos se comparan numéricamente con `compareTo`.
3. Un ID nulo va después de los IDs válidos.
4. Ante IDs iguales o ambos nulos, usar el nombre como desempate estable.

**Step 3: Conectar el provider y eliminar el mapa manual**

Reemplazar el bloque de agrupamiento y `_classOrder` por:

```dart
return groupMembersByClass(
  members,
  noClassLabel: tr('members.errors.no_class'),
);
```

**Step 4: Ejecutar GREEN, formatear y analizar**

Run:

```bash
cd sacdia-app
dart format lib/features/members/presentation/providers/members_providers.dart \
  test/features/members/presentation/providers/members_by_class_provider_test.dart
flutter test test/features/members/presentation/providers/members_by_class_provider_test.dart
flutter analyze lib/features/members/presentation/providers/members_providers.dart \
  test/features/members/presentation/providers/members_by_class_provider_test.dart
git diff --check
```

Expected: prueba y analyzer sin errores, sin ejecutar builds.

**Step 5: Commit**

```bash
cd sacdia-app
git add lib/features/members/presentation/providers/members_providers.dart \
  test/features/members/presentation/providers/members_by_class_provider_test.dart
git commit -m "fix: order member classes by ID"
```
