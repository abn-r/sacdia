# Post-Registration Logout Button Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Agregar un `IconButton` de cierre de sesión en el header del shell de post-registro, con diálogo de confirmación antes de ejecutar el logout.

**Architecture:** Se modifica únicamente `post_registration_shell.dart`. Se agrega el `IconButton` en la `Row` del header (entre el título y el badge de paso), y un método privado `_showLogoutDialog()` que muestra un `AlertDialog`. Al confirmar, llama a `ref.read(authNotifierProvider.notifier).signOut()` — el router ya redirige a login automáticamente.

**Tech Stack:** Flutter, Riverpod (`ConsumerStatefulWidget`), GoRouter (redirect automático), `AuthNotifier` (ya existente).

---

### Task 1: Agregar el botón de logout y el diálogo de confirmación

**Files:**
- Modify: `sacdia-app/lib/features/post_registration/presentation/views/post_registration_shell.dart`

**Contexto del archivo:**
El shell usa `ConsumerStatefulWidget`. El header está en `build()`, dentro de un `StaggeredListItem`, en una `Row` con:
- `Expanded(child: Text('Completar perfil'))` — a la izquierda
- `AnimatedSwitcher(child: Container(...badge 'X de 3'))` — a la derecha

**Step 1: Agregar import de AuthNotifier**

Verificar que el archivo ya tenga (o agregar) el import necesario para `authNotifierProvider`:

```dart
import '../../../auth/presentation/providers/auth_providers.dart';
```

Buscar si ya existe ese import. Si no, agregar junto a los otros imports al inicio del archivo.

**Step 2: Agregar el método `_showLogoutDialog()`**

Dentro de `_PostRegistrationShellState`, antes del método `build()`, agregar:

```dart
Future<void> _showLogoutDialog() async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('¿Cerrar sesión?'),
      content: const Text(
        'Si cierras sesión ahora, deberás completar este proceso cuando vuelvas a ingresar.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(ctx).colorScheme.error,
          ),
          child: const Text('Cerrar sesión'),
        ),
      ],
    ),
  );

  if (confirmed == true && mounted) {
    await ref.read(authNotifierProvider.notifier).signOut();
  }
}
```

**Step 3: Agregar el `IconButton` en la `Row` del header**

Ubicar la `Row` dentro del primer `StaggeredListItem` en `build()`. Actualmente tiene:

```dart
Row(
  children: [
    Expanded(
      child: Text(
        'Completar perfil',
        ...
      ),
    ),
    // Step counter badge — animates value change implicitly
    AnimatedSwitcher(
      ...
    ),
  ],
),
```

Reemplazar por (agregar el `IconButton` entre el `Expanded` y el `AnimatedSwitcher`):

```dart
Row(
  children: [
    Expanded(
      child: Text(
        'Completar perfil',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.lightText,
            ),
      ),
    ),
    IconButton(
      onPressed: _showLogoutDialog,
      icon: const Icon(Icons.logout_rounded),
      color: AppColors.lightText,
      tooltip: 'Cerrar sesión',
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
    ),
    const SizedBox(width: 8),
    // Step counter badge — animates value change implicitly
    AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: Container(
        key: ValueKey(currentStep),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '$currentStep de 3',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ),
    ),
  ],
),
```

**Step 4: Verificar con el analyzer**

```bash
/Users/abner/develop/flutter/bin/flutter analyze sacdia-app/lib/features/post_registration/presentation/views/post_registration_shell.dart
```

Resultado esperado: `No issues found!`

**Step 5: Commit**

```bash
git add sacdia-app/lib/features/post_registration/presentation/views/post_registration_shell.dart
git commit -m "feat(app): add logout button to post-registration shell with confirmation dialog"
```
