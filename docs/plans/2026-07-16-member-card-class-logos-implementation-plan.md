# Member Card Class Logos Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Reemplazar el ícono genérico de escuela por el logo local de clase en cada tarjeta de miembro.

**Architecture:** `MemberCard` resolverá el asset de `member.currentClass` con `AppColors.classLogoAsset`. Una clase mapeada mostrará un logo decorativo de 18 dp; una clase no mapeada conservará el ícono actual y la ausencia de clase seguirá ocultando la fila completa.

**Tech Stack:** Flutter, Dart, easy_localization, flutter_test, assets PNG locales.

---

## Restricciones de ejecución

- Trabajar directamente en `sacdia-app` sobre `development`.
- Aplicar TDD: test rojo antes de cambiar producción.
- No ejecutar `flutter build`, `flutter run` ni crear una rama alternativa.
- No modificar entidades, providers, backend ni assets existentes.

### Task 1: Escribir los tests rojos de `MemberCard`

**Files:**
- Create: `sacdia-app/test/features/members/presentation/widgets/member_card_test.dart`
- Read: `sacdia-app/lib/features/members/domain/entities/club_member.dart`
- Read: `sacdia-app/lib/core/theme/app_colors.dart`

**Step 1: Preparar el host localizado y el miembro fixture**

Crear un helper que inicialice `EasyLocalization`, envuelva la tarjeta en
`MaterialApp` y construya un `ClubMember` sin avatar. El helper debe recibir
`currentClass` para cubrir cada estado sin depender de providers.

**Step 2: Especificar una clase con logo**

Renderizar una tarjeta con `currentClass: 'Amigo'` y verificar:

```dart
expect(find.byKey(const ValueKey('member-card-class-logo-Amigo')), findsOneWidget);
expect(find.text('Amigo'), findsOneWidget);

final image = tester.widget<Image>(
  find.byKey(const ValueKey('member-card-class-logo-Amigo')),
);
expect((image.image as AssetImage).assetName, 'assets/img/logos-clases/CQ-01.png');
```

**Step 3: Especificar fallback y ausencia de clase**

Renderizar `currentClass: 'Clase desconocida'` y comprobar que no hay logo
pero sí el fallback identificado por
`ValueKey('member-card-class-fallback-icon')`. Renderizar después
`currentClass: null` y comprobar que no están ni el texto de clase ni el
fallback.

**Step 4: Ejecutar RED**

Run:

```bash
cd sacdia-app
flutter test test/features/members/presentation/widgets/member_card_test.dart
```

Expected: FAIL porque todavía no existen el logo ni la key de fallback de la
tarjeta.

### Task 2: Resolver y mostrar el logo en la tarjeta

**Files:**
- Modify: `sacdia-app/lib/features/members/presentation/widgets/member_card.dart:77-105`
- Test: `sacdia-app/test/features/members/presentation/widgets/member_card_test.dart`

**Step 1: Resolver el asset de la clase actual**

Dentro de la rama existente `member.currentClass != null`, obtener:

```dart
final classLogoAsset = AppColors.classLogoAsset(member.currentClass!);
```

**Step 2: Reemplazar el ícono de escuela sin duplicar contenido**

Si hay asset, renderizar:

```dart
Image.asset(
  classLogoAsset,
  key: ValueKey('member-card-class-logo-${member.currentClass}'),
  width: 18,
  height: 18,
  fit: BoxFit.contain,
  excludeFromSemantics: true,
)
```

Si no existe, conservar `HugeIcons.strokeRoundedSchool` y asignarle:

```dart
key: const ValueKey('member-card-class-fallback-icon'),
```

Conservar el espaciado actual de 4 dp hacia el texto y no cambiar el badge de
inscripción ni los cálculos de layout.

**Step 3: Ejecutar GREEN, formatear y analizar**

Run:

```bash
cd sacdia-app
dart format lib/features/members/presentation/widgets/member_card.dart \
  test/features/members/presentation/widgets/member_card_test.dart
flutter test test/features/members/presentation/widgets/member_card_test.dart
flutter analyze lib/features/members/presentation/widgets/member_card.dart \
  test/features/members/presentation/widgets/member_card_test.dart
git diff --check
```

Expected: pruebas y analyzer sin errores, sin ejecutar builds.

**Step 4: Commit**

```bash
cd sacdia-app
git add lib/features/members/presentation/widgets/member_card.dart \
  test/features/members/presentation/widgets/member_card_test.dart
git commit -m "feat: add class logos to member cards"
```
