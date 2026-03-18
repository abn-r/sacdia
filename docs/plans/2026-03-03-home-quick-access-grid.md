# Home Quick-Access Grid Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a 2-column quick-access grid of 8 feature modules to the DashboardView (tab "Inicio"), between the CurrentClassCard and the UpcomingActivitiesCard.

**Architecture:** Add new routes for 8 placeholder screens, create a reusable `QuickAccessGrid` widget in the dashboard feature, then inject it into the existing `DashboardView` scroll column. All new feature screens are placeholders using the existing `_PlaceholderScreen` pattern (already in router.dart).

**Tech Stack:** Flutter, Riverpod, go_router (GoRouter), HugeIcons, `AppColors` from `lib/core/theme/app_colors.dart`

---

## Context: Existing Code Structure

### Files to understand before starting:
- `sacdia-app/lib/core/config/router.dart` — GoRouter config, `_PlaceholderScreen`, `_MainShell` with bottom NavigationBar
- `sacdia-app/lib/core/config/route_names.dart` — Route constants
- `sacdia-app/lib/features/dashboard/presentation/views/dashboard_view.dart` — Main dashboard screen
- `sacdia-app/lib/features/dashboard/presentation/widgets/` — Existing widget dir (ClubInfoCard, CurrentClassCard, QuickStatsCard, UpcomingActivitiesCard, WelcomeHeader)
- `sacdia-app/lib/core/theme/app_colors.dart` — Color palette: `primary` (red), `secondary` (green), `accent` (yellow), `info` (blue), `secondaryDark` (dark green)

### Key patterns:
- **Navigation**: `context.go(RouteNames.someRoute)` via GoRouter
- **Icons**: `HugeIcon(icon: HugeIcons.strokeRoundedXxx, size: 24, color: color)`
- **Cards**: `SacCard(child: ...)` or plain `Container` with `BoxDecoration(borderRadius: BorderRadius.circular(16), color: surface, border: Border.all(color: lightBorder))`
- **Colors via context**: `context.sac.surface`, `context.sac.border`, `context.sac.textSecondary`
- **No tests** for UI widgets (Flutter widget tests are not in scope per project standards)

---

### Task 1: Add new route name constants

**Files:**
- Modify: `sacdia-app/lib/core/config/route_names.dart`

**Step 1: Add 8 new route constants**

Open `sacdia-app/lib/core/config/route_names.dart` and add these constants inside the `RouteNames` class, after the existing `homeProfile` line:

```dart
  // Módulos de acceso rápido (dentro del shell)
  static const String homeMembers = '/home/members';
  static const String homeClub = '/home/club';
  static const String homeEvidences = '/home/evidences';
  static const String homeFinances = '/home/finances';
  static const String homeUnits = '/home/units';
  static const String homeGroupedClass = '/home/grouped-class';
  static const String homeInsurance = '/home/insurance';
  static const String homeInventory = '/home/inventory';
```

**Step 2: Verify file compiles**

```bash
cd sacdia-app && flutter analyze lib/core/config/route_names.dart
```
Expected: no errors.

**Step 3: Commit**

```bash
cd sacdia-app
git add lib/core/config/route_names.dart
git commit -m "feat: add quick-access module route name constants"
```

---

### Task 2: Register new placeholder routes in GoRouter

**Files:**
- Modify: `sacdia-app/lib/core/config/router.dart`

**Step 1: Add 8 new GoRoute entries inside the existing `ShellRoute.routes` list**

In `router.dart`, find the `ShellRoute` block (around line 139). It currently has 4 routes (homeDashboard, homeClasses, homeActivities, homeProfile). Add 8 more routes after the `homeProfile` route, still inside `ShellRoute.routes`:

```dart
          GoRoute(
            path: RouteNames.homeMembers,
            pageBuilder: (context, state) => _buildPage(
              context, state,
              const _PlaceholderScreen(title: 'Miembros'),
            ),
          ),
          GoRoute(
            path: RouteNames.homeClub,
            pageBuilder: (context, state) => _buildPage(
              context, state,
              const _PlaceholderScreen(title: 'Club'),
            ),
          ),
          GoRoute(
            path: RouteNames.homeEvidences,
            pageBuilder: (context, state) => _buildPage(
              context, state,
              const _PlaceholderScreen(title: 'Carpeta de Evidencias'),
            ),
          ),
          GoRoute(
            path: RouteNames.homeFinances,
            pageBuilder: (context, state) => _buildPage(
              context, state,
              const _PlaceholderScreen(title: 'Finanzas'),
            ),
          ),
          GoRoute(
            path: RouteNames.homeUnits,
            pageBuilder: (context, state) => _buildPage(
              context, state,
              const _PlaceholderScreen(title: 'Unidades'),
            ),
          ),
          GoRoute(
            path: RouteNames.homeGroupedClass,
            pageBuilder: (context, state) => _buildPage(
              context, state,
              const _PlaceholderScreen(title: 'Clase Agrupada'),
            ),
          ),
          GoRoute(
            path: RouteNames.homeInsurance,
            pageBuilder: (context, state) => _buildPage(
              context, state,
              const _PlaceholderScreen(title: 'Seguros del Club'),
            ),
          ),
          GoRoute(
            path: RouteNames.homeInventory,
            pageBuilder: (context, state) => _buildPage(
              context, state,
              const _PlaceholderScreen(title: 'Inventario'),
            ),
          ),
```

**Step 2: Verify**

```bash
cd sacdia-app && flutter analyze lib/core/config/router.dart
```
Expected: no errors.

**Step 3: Commit**

```bash
cd sacdia-app
git add lib/core/config/router.dart
git commit -m "feat: register 8 quick-access placeholder routes in shell"
```

---

### Task 3: Create QuickAccessGrid widget

**Files:**
- Create: `sacdia-app/lib/features/dashboard/presentation/widgets/quick_access_grid.dart`

**Step 1: Create the file with this exact content**

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sacdia_app/core/config/route_names.dart';
import 'package:sacdia_app/core/theme/app_colors.dart';
import 'package:sacdia_app/core/theme/sac_colors.dart';

/// Grid 2×4 de acceso rápido a los módulos principales del sistema.
class QuickAccessGrid extends StatelessWidget {
  const QuickAccessGrid({super.key});

  static const List<_QuickAccessItem> _items = [
    _QuickAccessItem(
      label: 'Miembros',
      icon: HugeIcons.strokeRoundedUserGroup,
      color: AppColors.primary,
      route: RouteNames.homeMembers,
    ),
    _QuickAccessItem(
      label: 'Club',
      icon: HugeIcons.strokeRoundedCamping,
      color: AppColors.secondary,
      route: RouteNames.homeClub,
    ),
    _QuickAccessItem(
      label: 'Carpeta de\nEvidencias',
      icon: HugeIcons.strokeRoundedFolder01,
      color: AppColors.accent,
      route: RouteNames.homeEvidences,
    ),
    _QuickAccessItem(
      label: 'Finanzas',
      icon: HugeIcons.strokeRoundedCreditCard01,
      color: AppColors.info,
      route: RouteNames.homeFinances,
    ),
    _QuickAccessItem(
      label: 'Unidades',
      icon: HugeIcons.strokeRoundedCompass01,
      color: AppColors.secondary,
      route: RouteNames.homeUnits,
    ),
    _QuickAccessItem(
      label: 'Clase\nAgrupada',
      icon: HugeIcons.strokeRoundedBookOpen01,
      color: AppColors.primary,
      route: RouteNames.homeGroupedClass,
    ),
    _QuickAccessItem(
      label: 'Seguros\ndel Club',
      icon: HugeIcons.strokeRoundedShield01,
      color: AppColors.secondaryDark,
      route: RouteNames.homeInsurance,
    ),
    _QuickAccessItem(
      label: 'Inventario',
      icon: HugeIcons.strokeRoundedBox01,
      color: AppColors.accent,
      route: RouteNames.homeInventory,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.sac;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Acceso rápido',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.2,
          ),
          itemCount: _items.length,
          itemBuilder: (context, index) {
            final item = _items[index];
            return _QuickAccessTile(item: item);
          },
        ),
      ],
    );
  }
}

class _QuickAccessItem {
  final String label;
  final List<List<dynamic>> icon;
  final Color color;
  final String route;

  const _QuickAccessItem({
    required this.label,
    required this.icon,
    required this.color,
    required this.route,
  });
}

class _QuickAccessTile extends StatelessWidget {
  final _QuickAccessItem item;

  const _QuickAccessTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final c = context.sac;

    return Material(
      color: c.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.go(item.route),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.border),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: HugeIcon(
                    icon: item.icon,
                    size: 24,
                    color: item.color,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: c.text,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

**Step 2: Verify**

```bash
cd sacdia-app && flutter analyze lib/features/dashboard/presentation/widgets/quick_access_grid.dart
```
Expected: no errors. If a HugeIcons constant doesn't exist, replace with one that does (e.g. `strokeRoundedUserGroup` → `strokeRoundedUser02`, `strokeRoundedCamping` → `strokeRoundedTent01`, etc.). Run `flutter analyze` after each fix.

**Step 3: Commit**

```bash
cd sacdia-app
git add lib/features/dashboard/presentation/widgets/quick_access_grid.dart
git commit -m "feat: add QuickAccessGrid widget with 8 module tiles"
```

---

### Task 4: Inject QuickAccessGrid into DashboardView

**Files:**
- Modify: `sacdia-app/lib/features/dashboard/presentation/views/dashboard_view.dart`

**Step 1: Add import at the top of dashboard_view.dart**

After the existing import for `upcoming_activities_card.dart`, add:

```dart
import '../widgets/quick_access_grid.dart';
```

**Step 2: Insert the widget in the scroll column**

In `dashboard_view.dart`, find this block (around line 100-115):

```dart
                          // Quick stats row (animated counters inside)
                          QuickStatsCard(
                            honorsCompleted: dashboard.honorsCompleted,
                            honorsInProgress: dashboard.honorsInProgress,
                          ),
                          const SizedBox(height: 16),

                          // Upcoming activities
                          UpcomingActivitiesCard(
```

Replace it with:

```dart
                          // Quick stats row (animated counters inside)
                          QuickStatsCard(
                            honorsCompleted: dashboard.honorsCompleted,
                            honorsInProgress: dashboard.honorsInProgress,
                          ),
                          const SizedBox(height: 16),

                          // Quick access grid
                          const QuickAccessGrid(),
                          const SizedBox(height: 16),

                          // Upcoming activities
                          UpcomingActivitiesCard(
```

**Step 3: Verify full build**

```bash
cd sacdia-app && flutter analyze lib/features/dashboard/presentation/views/dashboard_view.dart
```
Expected: no errors.

**Step 4: Hot reload / run to verify visually**

```bash
cd sacdia-app && flutter run
```

Navigate to the "Inicio" tab. You should see:
- WelcomeHeader (saludo + avatar)
- ClubInfoCard
- CurrentClassCard (with class progress bar)
- QuickStatsCard (honores)
- **NEW: "Acceso rápido" section with 2×4 grid of tiles**
- UpcomingActivitiesCard

Tap each tile — it should navigate to a placeholder screen titled with the module name (e.g., "Miembros"). Press back to return.

**Step 5: Commit**

```bash
cd sacdia-app
git add lib/features/dashboard/presentation/views/dashboard_view.dart
git commit -m "feat: inject QuickAccessGrid into DashboardView between stats and activities"
```

---

## HugeIcons fallback reference

If a specific icon constant is missing, use these verified alternatives:

| Intended | Fallback |
|----------|---------|
| `strokeRoundedUserGroup` | `strokeRoundedUserMultiple02` |
| `strokeRoundedCamping` | `strokeRoundedHome01` |
| `strokeRoundedFolder01` | `strokeRoundedFolder02` |
| `strokeRoundedCreditCard01` | `strokeRoundedMoney01` |
| `strokeRoundedCompass01` | `strokeRoundedCompass` |
| `strokeRoundedBookOpen01` | `strokeRoundedBook01` |
| `strokeRoundedShield01` | `strokeRoundedSecurity` |
| `strokeRoundedBox01` | `strokeRoundedPackage` |

Run `flutter analyze` after every icon substitution to confirm.

---

## Done

After all 4 tasks and their commits, the feature is complete. No backend changes needed — all new screens are placeholders.
