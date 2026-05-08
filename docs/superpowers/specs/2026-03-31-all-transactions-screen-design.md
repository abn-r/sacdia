# All Transactions Screen — Design Specification

**Date**: 2026-03-31
**Feature**: Finances / All Transactions (`sacdia-app/lib/features/finances/`)
**Status**: Approved — Ready for Implementation
**Author**: Mobile Team

---

## Table of Contents

1. [Overview and Goals](#1-overview-and-goals)
2. [Design Decisions Summary](#2-design-decisions-summary)
3. [Screen Layout](#3-screen-layout)
4. [Component Specifications](#4-component-specifications)
5. [Color and Theme Specifications](#5-color-and-theme-specifications)
6. [Typography Scale](#6-typography-scale)
7. [Spacing and Radius Tokens](#7-spacing-and-radius-tokens)
8. [Interaction and Animation Specs](#8-interaction-and-animation-specs)
9. [Backend Endpoint Specification](#9-backend-endpoint-specification)
10. [State Management](#10-state-management)
11. [Preserved Behavior](#11-preserved-behavior)
12. [Files Affected](#12-files-affected)
13. [Dependencies](#13-dependencies)

---

## 1. Overview and Goals

### Summary

A new full-screen view that displays all financial transactions for a club, with server-side search, type filtering (all / income / expense), configurable date range, sortable columns, and infinite scroll pagination. It is accessed from the "Ver todo" link and the `_VerTodoLink` widget already present in `FinancesView`.

The screen follows the same dark-first visual language established in the finances redesign spec (`2026-03-31-finances-redesign-design.md`). All existing domain entities, use cases, and the `TransactionTile` widget are reused without modification.

### Goals

- Surface the full transaction history beyond what the current monthly view shows
- Provide search by description, category name, or amount
- Provide instant type filtering (All / Income / Expense) via a segmented tab control
- Provide flexible date range selection (current month, last 3 months, last year, custom range)
- Provide sort control (date, amount, category) with direction toggle
- Load results with page-based infinite scroll (20 items per page)
- Maintain full light and dark mode support using `context.sac` tokens
- Reuse `TransactionTile` and extract `_DateGroupHeader` as a shared widget

### Non-Goals

- No changes to existing domain entities or use cases
- No changes to the FinancesView business logic or its existing providers
- No changes to the TransactionTile widget
- No local offline caching — this screen is network-only (paginated data is not appropriate for offline)

---

## 2. Design Decisions Summary

| Decision | Rationale |
|---|---|
| Full-screen push route | This is a list-focused exploration screen, not a tab. Push navigation with back button is the natural pattern for drilling down into a detail list. |
| `SacSharedAxisRoute` transition | Consistent with existing navigation in `FinancesView` (used for `TransactionDetailView`). Horizontal shared axis is appropriate for same-hierarchy drill-down. |
| Server-side search, filter, sort, pagination | The full transaction history may contain hundreds or thousands of records. Sending all to the client is not viable. All filtering happens via query parameters. |
| 300ms search debounce | Prevents a new API call on every keystroke. 300ms is the standard debounce for search inputs — long enough to avoid spam, short enough to feel responsive. |
| Page-based pagination (not cursor) | Page + limit is simpler to implement on both the NestJS side (LIMIT/OFFSET in Prisma) and the Flutter side (tracking page number in scroll controller). For a list that is rarely mutated mid-session this is appropriate. |
| 20 items per page | Enough to fill one screen on most phones without excessive data transfer. The infinite scroll loads the next page automatically. |
| Segmented tab control for type filter | Three options (All, Income, Expense) are exhaustive and mutually exclusive. A segmented control is the most compact and legible UI for this case. |
| Bottom sheets for sort and range | Sort and range have multiple sub-options with possible secondary interactions (date pickers, direction toggles). A bottom sheet provides space without obstructing the list. |
| `AllTransactionsFilterNotifier` as `StateNotifier` | Filter state has multiple fields that change independently. A `StateNotifier` with an immutable value object is more maintainable than several separate `StateProvider`s. |
| `autoDispose` on all new providers | The screen is transient. Disposing state when the user navigates away avoids stale data on re-entry and reduces memory usage. |
| DateGroupHeader extracted to shared widget | Both `FinancesView` and `AllTransactionsView` need to group transactions by date. Extracting it eliminates duplication while keeping the same visual contract. |
| FAB only when `canManage && period open` | Consistent with `FinancesView`. Adding a transaction from the all-transactions view is valid as long as the period is open and the user has the role. |

---

## 3. Screen Layout

### Structure Overview (top to bottom)

```
┌────────────────────────────────────────────┐
│  ← back                Transacciones       │  ← AppBar (custom)
│               Marzo 2026     [sort] [range]│
├────────────────────────────────────────────┤
│  🔍  Buscar por nombre, categoría, monto…  │  ← SearchField (pinned)
├────────────────────────────────────────────┤
│  ┌────────┬──────────┬──────────────────┐  │
│  │  Todo  │ Ingresos │    Egresos        │  │  ← Segmented tabs
│  └────────┴──────────┴──────────────────┘  │
├────────────────────────────────────────────┤
│                                            │
│  Martes, 18 marzo                   $250  │  ← DateGroupHeader
│  ┌──────────────────────────────────────┐  │
│  │ [🏠 Alquiler]  Pago mensual          │  │
│  │                -$250.00   08:21 AM   │  │  ← TransactionTile
│  └──────────────────────────────────────┘  │
│                                            │
│  Lunes, 17 marzo                 $1,050   │  ← DateGroupHeader
│  ┌──────────────────────────────────────┐  │
│  │ [💰 Donación]  Diezmos miembros       │  │
│  │                +$800.00   10:00 AM   │  │
│  └──────────────────────────────────────┘  │
│  ┌──────────────────────────────────────┐  │
│  │ [🛒 Compras]   Materiales evento     │  │
│  │                -$250.00   14:30 PM   │  │
│  └──────────────────────────────────────┘  │
│                                            │
│  ─────────  Cargando más  ─────────        │  ← pagination loader
│                                            │
│                           ╭─────╮          │
│                           │  +  │          │  ← FAB (purple gradient)
│                           ╰─────╯          │
│  [80px bottom clearance]                   │
└────────────────────────────────────────────┘
```

### AppBar Layout Detail

```
┌────────────────────────────────────────────┐
│  ←    Transacciones              [⇅] [📅]  │
│       Marzo 2026                           │
└────────────────────────────────────────────┘
```

- Left: system back button (`Navigator.pop`)
- Center-left (aligned left): title + subtitle column
- Right: two `IconButton`s — sort and range

### Sort Bottom Sheet Layout

```
╭────────────────────────────────────────────╮
│  ─────  (drag handle)                      │
│                                            │
│  Ordenar por                               │  ← 16px, w700
│                                            │
│  ● Por fecha         ↓ Más reciente        │  ← active option, direction
│  ○ Por monto           Más alto primero    │
│  ○ Por categoría       A → Z               │
│                                            │
│  ──────────────────────────────────────    │
│  [  Aplicar  ]                             │  ← FilledButton primary
╰────────────────────────────────────────────╯
```

### Range Bottom Sheet Layout

```
╭────────────────────────────────────────────╮
│  ─────  (drag handle)                      │
│                                            │
│  Rango de fechas                           │  ← 16px, w700
│                                            │
│  ● Este mes                                │  ← default selected
│  ○ Últimos 3 meses                         │
│  ○ Último año                              │
│  ○ Rango personalizado                     │
│    ┌────────────┐  ┌────────────┐          │
│    │ 15 Mar 26  │  │ 28 Mar 26  │          │  ← shown when custom active
│    └────────────┘  └────────────┘          │
│     Desde             Hasta                │
│                                            │
│  [  Aplicar  ]                             │
╰────────────────────────────────────────────╯
```

### Empty State Layout

```
┌────────────────────────────────────────────┐
│  [SearchField + Tabs — always visible]     │
│                                            │
│                                            │
│          🔍  (HugeIcon, 56px, tertiary)    │
│                                            │
│     No se encontraron transacciones        │  ← 15px, w600, textSecondary
│                                            │
│   Probá con otros términos o cambiá        │  ← 13px, w400, textTertiary
│   el rango de fechas.                      │
│                                            │
└────────────────────────────────────────────┘
```

---

## 4. Component Specifications

### 4.1 `AllTransactionsView` — NEW SCREEN

**File**: `lib/features/finances/presentation/views/all_transactions_view.dart`

**Type**: `ConsumerStatefulWidget` (needs a `ScrollController` for infinite scroll)

**Constructor**:
```dart
class AllTransactionsView extends ConsumerStatefulWidget {
  final SelectedMonth initialMonth;   // passed from FinancesView

  const AllTransactionsView({
    super.key,
    required this.initialMonth,
  });
```

**Scaffold structure**:
```dart
Scaffold(
  backgroundColor: context.sac.background,
  floatingActionButton: showFab ? _AddFab(onTap: _openAddSheet) : null,
  floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
  body: SafeArea(
    child: Column(
      children: [
        _AllTransactionsAppBar(...),     // custom, not SliverAppBar
        TransactionSearchField(...),      // always pinned below appbar
        TransactionTypeTabs(...),         // segmented control
        Expanded(child: _TransactionList(...)),  // scroll region
      ],
    ),
  ),
)
```

**Scroll controller** (`_scrollController`):
- Attached to the `ListView` inside `_TransactionList`
- Listener checks: `offset >= maxScrollExtent - 200`
- When condition is true and `hasNextPage && !isLoadingMore`: calls `ref.read(allTransactionsFilterNotifierProvider.notifier).loadNextPage()`

**Pull-to-refresh**:
- `RefreshIndicator` wrapping `_TransactionList`
- `onRefresh`: calls notifier `reset()` which resets to page 1 and re-fetches

**initState**:
- Reads `initialMonth` and calls `ref.read(allTransactionsFilterNotifierProvider.notifier).initWithMonth(initialMonth)` after the first frame via `WidgetsBinding.instance.addPostFrameCallback`

---

### 4.2 `_AllTransactionsAppBar` — INTERNAL WIDGET

**Type**: `StatelessWidget` (receives callbacks and current subtitle text)

**Visual spec**:
```
Container(
  color: context.sac.background,
  padding: EdgeInsets.fromLTRB(0, 0, 8, 0),
  child: Row(
    children: [
      BackButton(color: context.sac.text),         // 44x44 tap target
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Transacciones")                  // 28px, w800, text
            Text(rangeLabel)                       // 14px, w400, textSecondary
          ]
        )
      ),
      IconButton(                                  // sort
        icon: HugeIcon(HugeIcons.strokeRoundedSortByDown02, 22, textSecondary),
        onTap: onSortTap,
      ),
      IconButton(                                  // range
        icon: HugeIcon(HugeIcons.strokeRoundedCalendar03, 22, textSecondary),
        onTap: onRangeTap,
      ),
    ]
  )
)
```

**`rangeLabel` logic** (resolved by the notifier / view):

| Filter state | Label |
|---|---|
| `startDate = first day of current month, endDate = last day` | `"Marzo 2026"` (formatted month+year) |
| Last 3 months from today | `"Últimos 3 meses"` |
| Last 12 months | `"Último año"` |
| Custom range | `"15 Mar – 28 Mar 2026"` (abbreviated format) |

Formatting uses `DateFormat('MMMM yyyy', 'es')` for month presets and `DateFormat('d MMM yyyy', 'es')` for custom ranges.

**Constructor**:
```dart
class _AllTransactionsAppBar extends StatelessWidget {
  final String rangeLabel;
  final VoidCallback onSortTap;
  final VoidCallback onRangeTap;
```

---

### 4.3 `TransactionSearchField` — NEW WIDGET

**File**: `lib/features/finances/presentation/widgets/transaction_search_field.dart`

**Type**: `StatefulWidget` (manages `TextEditingController` and debounce `Timer`)

**Visual spec**:
```
Container(
  margin: EdgeInsets.fromLTRB(16, 8, 16, 8),
  decoration: BoxDecoration(
    color: searchFieldBg       // dark: #1A1A1A  |  light: #F8FAFC
    borderRadius: 12
    border: Border.all(
      color: searchFieldBorder // dark: #252525  |  light: #E2E8F0
      width: 1.0
    )
  ),
  child: Row(
    children: [
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: HugeIcon(HugeIcons.strokeRoundedSearch01, 18, textTertiary),
      ),
      Expanded(
        child: TextField(
          controller: _controller,
          decoration: InputDecoration(
            hintText: "Buscar por nombre, categoría, monto...",
            hintStyle: 14px, w400, textTertiary,
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 14),
          ),
          style: 14px, w400, text,
          onChanged: _onChanged,    // triggers debounce
        ),
      ),
      if (_controller.text.isNotEmpty)
        IconButton(
          icon: HugeIcon(HugeIcons.strokeRoundedCancel01, 18, textTertiary),
          onPressed: _onClear,
        ),
    ]
  )
)
```

**Debounce behavior**:
- `_debounce`: `Timer?` field, cancelled on every `_onChanged` call
- New timer set to `Duration(milliseconds: 300)`
- On fire: calls `widget.onSearch(value)`
- `_onClear`: clears controller text, cancels timer, immediately calls `widget.onSearch('')`
- `dispose()`: cancels `_debounce` timer

**Constructor**:
```dart
class TransactionSearchField extends StatefulWidget {
  final ValueChanged<String> onSearch;
  final String initialValue;

  const TransactionSearchField({
    super.key,
    required this.onSearch,
    this.initialValue = '',
  });
```

**Colors** (hardcoded, no `context.sac` equivalent — same approach as `TransactionTile`):

| Token | Dark | Light |
|---|---|---|
| `searchFieldBg` | `Color(0xFF1A1A1A)` | `Color(0xFFF8FAFC)` |
| `searchFieldBorder` | `Color(0xFF252525)` | `Color(0xFFE2E8F0)` |
| Search icon / placeholder | `context.sac.textTertiary` | `context.sac.textTertiary` |
| Input text | `context.sac.text` | `context.sac.text` |

---

### 4.4 `TransactionTypeTabs` — NEW WIDGET

**File**: `lib/features/finances/presentation/widgets/transaction_type_tabs.dart`

**Type**: `StatelessWidget`

**Visual spec**:
```
Container(
  margin: EdgeInsets.fromLTRB(16, 0, 16, 8),
  padding: EdgeInsets.all(3),
  decoration: BoxDecoration(
    color: tabContainer   // dark: #1A1A1A  |  light: #F1F5F9
    borderRadius: 14
  ),
  child: Row(
    children: [
      for each (label, type) in tabs:
        Expanded(
          child: GestureDetector(
            onTap: () => onChanged(type),
            child: AnimatedContainer(
              duration: Duration(milliseconds: 180),
              padding: EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                color: isActive
                  ? tabActive    // dark: #333333  |  light: #E2E8F0
                  : Colors.transparent
                borderRadius: 11
              ),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: 13px,
                       w600 if active / w400 if inactive,
                       text if active / textSecondary if inactive,
              )
            )
          )
        )
    ]
  )
)
```

**Tab definitions**:

| Index | Label | `TransactionType?` value |
|---|---|---|
| 0 | `"Todo"` | `null` (all types) |
| 1 | `"Ingresos"` | `TransactionType.income` |
| 2 | `"Egresos"` | `TransactionType.expense` |

**Animation**: `AnimatedContainer` with 180ms duration — smooth background color transition between active states.

**Constructor**:
```dart
class TransactionTypeTabs extends StatelessWidget {
  final TransactionType? selected;      // null = Todo
  final ValueChanged<TransactionType?> onChanged;

  const TransactionTypeTabs({
    super.key,
    required this.selected,
    required this.onChanged,
  });
```

**Colors** (hardcoded):

| Token | Dark | Light |
|---|---|---|
| `tabContainer` | `Color(0xFF1A1A1A)` | `Color(0xFFF1F5F9)` |
| `tabActive` | `Color(0xFF333333)` | `Color(0xFFE2E8F0)` |

---

### 4.5 `DateGroupHeader` — EXTRACTED SHARED WIDGET

**File**: `lib/features/finances/presentation/widgets/date_group_header.dart`

**Type**: `StatelessWidget` — extracted verbatim from `_DateGroupHeader` inside `finances_view.dart`.

**Visual spec** (unchanged from current implementation):
```dart
Padding(
  padding: EdgeInsets.fromLTRB(16, 12, 16, 6),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(capitalizedDate)   // 11px, w600, textSecondary
      Text(totalFormatted)    // 11px, w600, textTertiary
    ]
  )
)
```

**Date label format**: `DateFormat('EEEE, d MMMM', 'es')` — first letter uppercased.

**Amount format**: `NumberFormat.currency(locale: 'es', symbol: '\$', decimalDigits: 2)` on `dailyTotal.abs()`.

**Constructor**:
```dart
class DateGroupHeader extends StatelessWidget {
  final DateTime date;
  final double dailyTotal;

  const DateGroupHeader({
    super.key,
    required this.date,
    required this.dailyTotal,
  });
```

**Migration note**: `finances_view.dart` replaces its local `_DateGroupHeader` with this exported widget. Import path: `'../widgets/date_group_header.dart'`.

---

### 4.6 `SortBottomSheet` — NEW WIDGET

**File**: `lib/features/finances/presentation/widgets/sort_bottom_sheet.dart`

**Type**: `StatefulWidget` (manages local selection state before the user taps Apply)

**Launch pattern** (from `AllTransactionsView`):
```dart
showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: Colors.transparent,
  builder: (_) => SortBottomSheet(
    currentSortBy: filter.sortBy,
    currentSortOrder: filter.sortOrder,
    onApply: (sortBy, sortOrder) {
      ref.read(allTransactionsFilterNotifierProvider.notifier)
         .updateSort(sortBy: sortBy, sortOrder: sortOrder);
    },
  ),
);
```

**Visual spec**:
```
Container(
  decoration: BoxDecoration(
    color: context.sac.surface,
    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
  ),
  padding: EdgeInsets.fromLTRB(20, 12, 20, 32),
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      _DragHandle(),
      SizedBox(height: 16),
      Align(
        alignment: Alignment.centerLeft,
        child: Text("Ordenar por", style: 16px, w700, text),
      ),
      SizedBox(height: 16),
      // Option rows:
      _SortOption(label: "Por fecha",      description: sortOrderLabel(sortBy: 'date',     ...))
      _SortOption(label: "Por monto",      description: sortOrderLabel(sortBy: 'amount',   ...))
      _SortOption(label: "Por categoría",  description: sortOrderLabel(sortBy: 'category', ...))
      SizedBox(height: 20),
      _BottomSheetApplyButton(onApply: _onApply),
    ]
  )
)
```

**`_SortOption` widget** (internal):
```
Row:
  Radio<String>(value: sortKey, groupValue: _selectedSortBy, onChanged: _onSortByChanged)
  SizedBox(width: 12)
  Expanded:
    Column(crossAxisAlignment: start):
      Text(label)       // 15px, w500, text
      Text(description) // 12px, w400, textSecondary
  if (_selectedSortBy == sortKey):
    GestureDetector(
      onTap: _toggleSortOrder,
      child: HugeIcon(
        icon: _sortOrder == 'asc'
          ? HugeIcons.strokeRoundedArrowUp01
          : HugeIcons.strokeRoundedArrowDown01,
        size: 20,
        color: textSecondary,
      )
    )
```

**Sort description labels**:

| `sortBy` | `sortOrder: desc` | `sortOrder: asc` |
|---|---|---|
| `'date'` | `"Más reciente primero"` | `"Más antiguo primero"` |
| `'amount'` | `"Mayor monto primero"` | `"Menor monto primero"` |
| `'category'` | `"A → Z"` | `"Z → A"` |

**Constructor**:
```dart
class SortBottomSheet extends StatefulWidget {
  final String currentSortBy;
  final String currentSortOrder;
  final void Function(String sortBy, String sortOrder) onApply;

  const SortBottomSheet({
    super.key,
    required this.currentSortBy,
    required this.currentSortOrder,
    required this.onApply,
  });
```

---

### 4.7 `RangeBottomSheet` — NEW WIDGET

**File**: `lib/features/finances/presentation/widgets/range_bottom_sheet.dart`

**Type**: `StatefulWidget` (manages selection and custom date fields locally)

**Launch pattern** (from `AllTransactionsView`):
```dart
showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: Colors.transparent,
  builder: (_) => RangeBottomSheet(
    currentPreset: filter.rangePreset,
    currentStart: filter.startDate,
    currentEnd: filter.endDate,
    onApply: (preset, start, end) {
      ref.read(allTransactionsFilterNotifierProvider.notifier)
         .updateRange(preset: preset, startDate: start, endDate: end);
    },
  ),
);
```

**Range preset enum** (defined in the same file or a separate model file):
```dart
enum DateRangePreset {
  thisMonth,
  last3Months,
  lastYear,
  custom,
}
```

**Visual spec**:
```
Container(
  decoration: BoxDecoration(
    color: context.sac.surface,
    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
  ),
  padding: EdgeInsets.fromLTRB(20, 12, 20, 32),
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      _DragHandle(),
      SizedBox(height: 16),
      Align(
        alignment: Alignment.centerLeft,
        child: Text("Rango de fechas", style: 16px, w700, text),
      ),
      SizedBox(height: 16),
      _RangeOption(preset: DateRangePreset.thisMonth,    label: "Este mes"),
      _RangeOption(preset: DateRangePreset.last3Months,  label: "Últimos 3 meses"),
      _RangeOption(preset: DateRangePreset.lastYear,     label: "Último año"),
      _RangeOption(preset: DateRangePreset.custom,       label: "Rango personalizado"),
      // Shown only when custom is active:
      AnimatedSize(
        duration: Duration(milliseconds: 200),
        child: _selectedPreset == DateRangePreset.custom
          ? _CustomDateFields(
              startDate: _customStart,
              endDate: _customEnd,
              onStartChanged: _setCustomStart,
              onEndChanged: _setCustomEnd,
            )
          : const SizedBox.shrink(),
      ),
      SizedBox(height: 20),
      _BottomSheetApplyButton(onApply: _onApply),
    ]
  )
)
```

**`_RangeOption` widget** (internal):
```
Row:
  Radio<DateRangePreset>(value: preset, groupValue: _selected, ...)
  SizedBox(width: 12)
  Text(label)  // 15px, w500, text
```

**`_CustomDateFields` widget** (internal):
```
Padding(
  padding: EdgeInsets.only(top: 12),
  child: Row(
    children: [
      Expanded(child: _DateField(label: "Desde", date: startDate, onChanged: ...)),
      SizedBox(width: 12),
      Expanded(child: _DateField(label: "Hasta", date: endDate, onChanged: ...)),
    ]
  )
)
```

**`_DateField` widget** (internal):
```
GestureDetector(
  onTap: () => showDatePicker(...),
  child: Container(
    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: context.sac.surfaceVariant,
      borderRadius: 12,
      border: Border.all(color: context.sac.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label)          // 11px, w500, textTertiary
        SizedBox(height: 4)
        Text(formattedDate)  // 13px, w600, text
      ]
    )
  )
)
```

Date picker uses `showDatePicker` with `initialDate`, `firstDate`, `lastDate`. Theme is inherited from the app's existing `ThemeData`.

**Constructor**:
```dart
class RangeBottomSheet extends StatefulWidget {
  final DateRangePreset currentPreset;
  final DateTime? currentStart;
  final DateTime? currentEnd;
  final void Function(DateRangePreset preset, DateTime? start, DateTime? end) onApply;

  const RangeBottomSheet({
    super.key,
    required this.currentPreset,
    this.currentStart,
    this.currentEnd,
    required this.onApply,
  });
```

---

### 4.8 `_DragHandle` — SHARED INTERNAL WIDGET

Used inside both `SortBottomSheet` and `RangeBottomSheet`. Can be extracted to `lib/core/widgets/` if not already present.

```
Center(
  child: Container(
    width: 40,
    height: 4,
    decoration: BoxDecoration(
      color: context.sac.border,
      borderRadius: BorderRadius.circular(2),
    ),
  ),
)
```

---

### 4.9 `_BottomSheetApplyButton` — SHARED INTERNAL WIDGET

Used inside both bottom sheets.

```
SizedBox(
  width: double.infinity,
  child: FilledButton(
    onPressed: onApply,
    style: FilledButton.styleFrom(
      backgroundColor: AppColors.primary,
      padding: EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    child: Text("Aplicar", style: 15px, w600, white),
  )
)
```

---

### 4.10 `_TransactionList` — INTERNAL WIDGET IN `all_transactions_view.dart`

**Type**: Internal `ConsumerWidget` or inline in `AllTransactionsView.build`

**Responsibilities**:
- Watches `allTransactionsProvider` (list of `FinanceTransaction`) and pagination state
- Groups transactions by date using the same algorithm as `FinancesView._buildGroupedTransactions`
- Renders `DateGroupHeader` + `TransactionTile` per group
- Appends a `_LoadMoreIndicator` at the bottom when more pages exist
- Shows `_EmptyTransactionsAll` when list is empty and not loading
- Shows `_AllTransactionsErrorState` on error

**`_LoadMoreIndicator`** (inline):
```
Padding(
  padding: EdgeInsets.symmetric(vertical: 20),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
      ),
      SizedBox(width: 10),
      Text("Cargando más…", style: 12px, w400, textTertiary),
    ]
  )
)
```

**`_EmptyTransactionsAll`** (inline, search-aware):
```
Padding(
  padding: EdgeInsets.all(40),
  child: Column(
    children: [
      HugeIcon(HugeIcons.strokeRoundedSearch01, 56, textTertiary),
      SizedBox(height: 12),
      Text(
        "No se encontraron transacciones",
        style: 15px, w600, textSecondary, textAlign: center,
      ),
      SizedBox(height: 4),
      Text(
        hasActiveSearch
          ? "Probá con otros términos o cambiá el rango de fechas."
          : "No hay transacciones para el rango seleccionado.",
        style: 13px, w400, textTertiary, textAlign: center,
      ),
    ]
  )
)
```

`hasActiveSearch` = `filter.search != null && filter.search!.isNotEmpty`.

---

## 5. Color and Theme Specifications

All semantic tokens use `context.sac` (resolved via `SacColorsExtension` on `BuildContext`). Hardcoded hex values are used only where no semantic token maps cleanly — following the same pattern as `TransactionTile`.

### Semantic Token Usage

| Surface / Element | Token | Dark value | Light value |
|---|---|---|---|
| Screen background | `context.sac.background` | `#000000` | `#FFFFFF` |
| Surface (cards, bottom sheets) | `context.sac.surface` | `#111111` | `#F4F6F8` |
| Surface variant (chips bg, fields bg) | `context.sac.surfaceVariant` | `#1C1C1E` | `#EAEEF2` |
| Border (inputs, cards) | `context.sac.border` | `#2A2A2A` | `#D4DBE3` |
| Border light (subtle dividers) | `context.sac.borderLight` | `#1C1C1E` | `#EEF1F5` |
| Primary text | `context.sac.text` | `#F2F2F2` | `#0F172A` |
| Secondary text | `context.sac.textSecondary` | `#8A8A8A` | `#475569` |
| Tertiary text / muted | `context.sac.textTertiary` | `#5C5C5C` | `#94A3B8` |
| Modal barrier | `context.sac.barrierColor` | `rgba(0,0,0,0.70)` | `rgba(0,0,0,0.50)` |

### Hardcoded Values (Component-Specific)

| Component | Token name | Dark | Light |
|---|---|---|---|
| `TransactionSearchField` bg | `searchFieldBg` | `#1A1A1A` | `#F8FAFC` |
| `TransactionSearchField` border | `searchFieldBorder` | `#252525` | `#E2E8F0` |
| `TransactionTypeTabs` outer bg | `tabContainer` | `#1A1A1A` | `#F1F5F9` |
| `TransactionTypeTabs` active tab | `tabActive` | `#333333` | `#E2E8F0` |
| Transaction tile surface | (from `TransactionTile`) | `#1A1A1A` | `#F8FAFC` |
| FAB gradient start | — | `#9333EA` | `#9333EA` |
| FAB gradient end | — | `#7C3AED` | `#7C3AED` |
| FAB shadow | — | `#9333EA` @ 40% | `#9333EA` @ 40% |
| Income amount color | — | `#4FBF9F` | `#2D8A70` |
| Expense amount color | — | `#DC2626` | `#DC2626` |

### Category Accent Colors

Inherited from `TransactionTile._accentColors` — no changes:

| `iconIndex` | Accent color |
|---|---|
| 1 | `#F59E0B` |
| 2 | `#6366F1` |
| 3 | `#3B82F6` |
| 4 | `#EC4899` |
| 5 | `#EF4444` |
| 6 | `#8B5CF6` |
| 7 | `#F97316` |
| 8 | `#10B981` |
| 9 | `#0EA5E9` |
| 10 | `#64748B` |
| default | `#6B7280` |

---

## 6. Typography Scale

All font sizes reference the design token system. No custom `TextStyle` objects create new font families — the app uses its configured `ThemeData` base font throughout.

| Element | Size | Weight | Color token | Notes |
|---|---|---|---|---|
| AppBar title "Transacciones" | 28px | w800 | `text` | Large header, left-aligned |
| AppBar subtitle (range label) | 14px | w400 | `textSecondary` | Dynamic text |
| Search field placeholder | 14px | w400 | `textTertiary` | `hintStyle` in `InputDecoration` |
| Search field input text | 14px | w400 | `text` | User-typed text |
| Tab active label | 13px | w600 | `text` | Bold when selected |
| Tab inactive label | 13px | w400 | `textSecondary` | Normal weight |
| Date group header date label | 11px | w600 | `textSecondary` | Uppercase month, e.g. "Martes, 18 marzo" |
| Date group header daily total | 11px | w600 | `textTertiary` | Right-aligned |
| Transaction description | 13px | w500 | `text` | From `TransactionTile` (unchanged) |
| Transaction registered by | 10px | w400 | `textTertiary` | From `TransactionTile` (unchanged) |
| Transaction amount | 15px | w700 | income/expense color | From `TransactionTile` (unchanged) |
| Transaction time | 10px | w400 | `textTertiary` | From `TransactionTile` (unchanged) |
| Bottom sheet title | 16px | w700 | `text` | "Ordenar por" / "Rango de fechas" |
| Sort/range option label | 15px | w500 | `text` | — |
| Sort/range option description | 12px | w400 | `textSecondary` | Direction hint beneath option |
| Apply button | 15px | w600 | white | `Colors.white` — on primary bg |
| Load more indicator | 12px | w400 | `textTertiary` | Inline with spinner |
| Empty state title | 15px | w600 | `textSecondary` | — |
| Empty state body | 13px | w400 | `textTertiary` | — |
| Date field label | 11px | w500 | `textTertiary` | Small label above date in `_DateField` |
| Date field value | 13px | w600 | `text` | Formatted date in `_DateField` |

---

## 7. Spacing and Radius Tokens

### Spacing

| Context | Value |
|---|---|
| Screen horizontal padding (list content) | `16px` — via `TransactionTile` margin |
| AppBar inner horizontal padding | `8px` right-side only (icon buttons have their own padding) |
| Search field margin horizontal | `16px` |
| Search field margin vertical | `8px` top and bottom |
| Tab control margin horizontal | `16px` |
| Tab control margin bottom | `8px` |
| Tab control inner padding | `3px` all sides (container inset) |
| Tab item vertical padding | `9px` top and bottom |
| Date group header padding | `fromLTRB(16, 12, 16, 6)` |
| Transaction tile margin | `symmetric(horizontal: 16, vertical: 4)` — from `TransactionTile` |
| Transaction tile padding | `symmetric(horizontal: 14, vertical: 12)` — from `TransactionTile` |
| Bottom sheet horizontal padding | `20px` |
| Bottom sheet bottom padding | `32px` |
| Bottom sheet between title and options | `16px` |
| Between sort/range options | `0px` — `ListTile`-style, no extra gap |
| Between bottom sheet options and Apply button | `20px` |
| Apply button vertical padding | `16px` |
| FAB bottom clearance | `80px` `SizedBox` at the end of the list |
| Load more indicator vertical padding | `20px` |
| Empty state padding | `40px` all sides |

### Border Radii

| Component | Radius |
|---|---|
| `TransactionSearchField` | `12px` |
| `TransactionTypeTabs` outer container | `14px` |
| `TransactionTypeTabs` active pill | `11px` |
| `TransactionTile` | `16px` — from existing widget |
| `_CategoryChip` inside tile | `12px` — from existing widget |
| Bottom sheet (top corners only) | `24px` vertical(top) |
| Apply button | `14px` |
| Date field container | `12px` |
| Drag handle | `2px` |
| FAB | circular (`BoxShape.circle`) |

---

## 8. Interaction and Animation Specs

### Search Field

| Trigger | Behavior |
|---|---|
| User types | Cancels previous debounce timer, starts new 300ms timer |
| Timer fires (300ms idle) | Calls `onSearch(value)` → notifier updates `search`, resets to page 1, triggers re-fetch |
| User taps X (clear) | Clears text, cancels timer, immediately calls `onSearch('')` |
| User taps outside / dismisses keyboard | No action — debounce continues naturally |

### Segmented Tabs

| Trigger | Behavior |
|---|---|
| Tap tab | `AnimatedContainer` transitions background in 180ms, `onChanged` fires immediately |
| `onChanged` in view | Notifier updates `type`, resets page to 1, triggers re-fetch |

### Sort/Range Bottom Sheets

| Trigger | Behavior |
|---|---|
| Tap sort icon | `showModalBottomSheet` with `SortBottomSheet` |
| Tap range icon | `showModalBottomSheet` with `RangeBottomSheet` |
| Tap option inside sheet | Updates local state within sheet (not committed yet) |
| Tap direction arrow in sort | Toggles `sortOrder` locally in sheet state |
| Tap Apply | Calls `onApply` callback, sheet closes via `Navigator.pop`, notifier commits changes, resets to page 1 |
| Sheet dismissed via drag / tap outside | No changes committed — previous filter preserved |

### Infinite Scroll

| Trigger | Behavior |
|---|---|
| `_scrollController` offset reaches `maxScrollExtent - 200px` | Triggers `loadNextPage()` if `hasNextPage && !isLoadingMore` |
| Next page loads | Appends items to existing list, increments page counter |
| Last page reached | `hasNextPage = false`, `_LoadMoreIndicator` removed |

### Pull-to-Refresh

| Trigger | Behavior |
|---|---|
| User pulls down on list | `RefreshIndicator` activates (spinner color: `AppColors.primary`) |
| `onRefresh` fires | Notifier calls `reset()`: page → 1, clears accumulated items, re-fetches from scratch |

### Filter/Sort State Changes

Any change to `type`, `search`, `sortBy`, `sortOrder`, `startDate`, or `endDate`:
1. Resets `page` to `1`
2. Clears the current accumulated transaction list
3. Triggers a fresh fetch via the provider

### FAB

Identical behavior to `FinancesView`:
- Tap: `showModalBottomSheet` with `AddTransactionSheet`
- After sheet dismisses: `ref.invalidate(allTransactionsProvider)` to refresh the list (if the notifier does not auto-invalidate)

### Navigation

| Action | Behavior |
|---|---|
| Back button / system back gesture | `Navigator.pop(context)` returns to `FinancesView` |
| Tap `TransactionTile` | `Navigator.push` with `SacSharedAxisRoute` to `TransactionDetailView` |
| Return from `TransactionDetailView` | No automatic refresh — detail view handles invalidation if edit/delete occurs |

### Page Transition (entry)

`AllTransactionsView` is pushed with `SacSharedAxisRoute` from `_openFullTransactionList` in `_FinanceBody`:
```dart
void _openFullTransactionList(BuildContext context, SelectedMonth initialMonth) {
  Navigator.push(
    context,
    SacSharedAxisRoute(
      builder: (_) => AllTransactionsView(initialMonth: initialMonth),
    ),
  );
}
```

---

## 9. Backend Endpoint Specification

### New Endpoint

```
GET /api/clubs/:clubId/finances/transactions
```

This endpoint is separate from the existing `GET /api/clubs/:clubId/finances?year=&month=` (which returns the `FinanceMonth` model with all-at-once data for a single month). This new endpoint supports pagination and is designed for the all-transactions screen.

### Query Parameters

| Parameter | Type | Default | Required | Description |
|---|---|---|---|---|
| `page` | `number` | `1` | No | Page number (1-indexed) |
| `limit` | `number` | `20` | No | Items per page (max: 100) |
| `type` | `string` | `null` | No | `"income"` or `"expense"`. Omit for all. |
| `search` | `string` | `null` | No | Full-text search across description, category name. Amount search by exact numeric match. |
| `startDate` | `string` | `null` | No | ISO 8601 date `YYYY-MM-DD` (inclusive) |
| `endDate` | `string` | `null` | No | ISO 8601 date `YYYY-MM-DD` (inclusive) |
| `sortBy` | `string` | `"date"` | No | `"date"`, `"amount"`, or `"category"` |
| `sortOrder` | `string` | `"desc"` | No | `"asc"` or `"desc"` |

### Request Example

```
GET /api/clubs/42/finances/transactions?page=1&limit=20&type=expense&search=comida&startDate=2026-01-01&endDate=2026-03-31&sortBy=amount&sortOrder=desc
```

### Response Schema

```json
{
  "data": [
    {
      "id": 1,
      "type": "expense",
      "amount": 124.00,
      "description": "Comida para el campamento",
      "notes": null,
      "date": "2026-01-23T08:21:00Z",
      "year": 2026,
      "month": 1,
      "category": {
        "id": 3,
        "name": "Compras",
        "iconIndex": 1,
        "typeCode": 2
      },
      "registeredByName": "Juan Pérez",
      "registeredAt": "2026-01-23T08:30:00Z",
      "modifiedByName": null,
      "modifiedAt": null
    }
  ],
  "meta": {
    "page": 1,
    "limit": 20,
    "total": 145,
    "totalPages": 8,
    "hasNextPage": true,
    "hasPreviousPage": false
  }
}
```

### Response Field Notes

- `data[].amount`: Returned as a decimal number (not integer cents). Consistent with the existing endpoint.
- `data[].type`: String `"income"` or `"expense"` — mapped to `TransactionType` enum in the Flutter model.
- `meta.total`: Total matching records across all pages (used for display like "145 transacciones").
- `meta.hasNextPage`: Convenience field to avoid `page < totalPages` calculation on the client.

### Backend Files (NestJS)

| File | Change |
|---|---|
| `src/finances/finances.controller.ts` | Add `@Get(':clubId/transactions')` handler |
| `src/finances/dto/get-all-transactions.dto.ts` | **NEW** — `class GetAllTransactionsDto` with `@IsOptional` decorators + `@Transform` for numeric parsing |
| `src/finances/finances.service.ts` | Add `getAllTransactions(clubId, dto)` method |
| `src/finances/finances.service.ts` | Prisma query: `findMany` with `WHERE` conditions, `orderBy`, `skip`/`take`, `_count` |

### Prisma Query Strategy

```typescript
// Pseudo-code — not final implementation
const where: Prisma.financeWhereInput = {
  club_id: clubId,
  ...(dto.type && { finance_categories: { type_code: dto.type === 'income' ? 1 : 2 } }),
  ...(dto.search && {
    OR: [
      { description: { contains: dto.search, mode: 'insensitive' } },
      { finance_categories: { name: { contains: dto.search, mode: 'insensitive' } } },
    ]
  }),
  ...(dto.startDate && { finance_date: { gte: new Date(dto.startDate) } }),
  ...(dto.endDate && { finance_date: { lte: new Date(`${dto.endDate}T23:59:59Z`) } }),
};

const orderBy = resolveOrderBy(dto.sortBy, dto.sortOrder);
// 'date'     → { finance_date: dto.sortOrder }
// 'amount'   → { amount: dto.sortOrder }
// 'category' → { finance_categories: { name: dto.sortOrder } }

const [total, records] = await Promise.all([
  prisma.finance.count({ where }),
  prisma.finance.findMany({ where, orderBy, skip: (page - 1) * limit, take: limit, include: { finance_categories: true, ... } }),
]);
```

---

## 10. State Management

### Filter State Value Object

```dart
// lib/features/finances/domain/entities/all_transactions_filter.dart (NEW)

import 'package:equatable/equatable.dart';
import 'transaction.dart';

enum DateRangePreset {
  thisMonth,
  last3Months,
  lastYear,
  custom,
}

class AllTransactionsFilter extends Equatable {
  final TransactionType? type;        // null = all
  final String? search;               // null or empty = no search
  final DateRangePreset rangePreset;
  final DateTime? startDate;
  final DateTime? endDate;
  final String sortBy;                // 'date' | 'amount' | 'category'
  final String sortOrder;             // 'asc' | 'desc'
  final int page;
  final bool isLoadingMore;
  final bool hasNextPage;

  const AllTransactionsFilter({
    this.type,
    this.search,
    required this.rangePreset,
    this.startDate,
    this.endDate,
    this.sortBy = 'date',
    this.sortOrder = 'desc',
    this.page = 1,
    this.isLoadingMore = false,
    this.hasNextPage = true,
  });

  AllTransactionsFilter copyWith({
    TransactionType? type,
    Object? search = _sentinel,       // use sentinel to allow null
    DateRangePreset? rangePreset,
    DateTime? startDate,
    DateTime? endDate,
    String? sortBy,
    String? sortOrder,
    int? page,
    bool? isLoadingMore,
    bool? hasNextPage,
  });

  @override
  List<Object?> get props => [
    type, search, rangePreset, startDate, endDate,
    sortBy, sortOrder, page, isLoadingMore, hasNextPage,
  ];
}
```

### `AllTransactionsFilterNotifier`

```dart
// Added to: lib/features/finances/presentation/providers/finances_providers.dart

class AllTransactionsFilterNotifier
    extends AutoDisposeNotifier<AllTransactionsFilter> {

  @override
  AllTransactionsFilter build() => AllTransactionsFilter(
    rangePreset: DateRangePreset.thisMonth,
    startDate: _firstDayOfMonth(DateTime.now()),
    endDate: _lastDayOfMonth(DateTime.now()),
  );

  /// Called from AllTransactionsView.initState to seed the initial month.
  void initWithMonth(SelectedMonth month) {
    state = state.copyWith(
      startDate: _firstDayOfMonth(DateTime(month.year, month.month)),
      endDate: _lastDayOfMonth(DateTime(month.year, month.month)),
    );
  }

  void updateSearch(String search) {
    state = state.copyWith(search: search.isEmpty ? null : search, page: 1, hasNextPage: true);
  }

  void updateType(TransactionType? type) {
    state = state.copyWith(type: type, page: 1, hasNextPage: true);
  }

  void updateSort({required String sortBy, required String sortOrder}) {
    state = state.copyWith(sortBy: sortBy, sortOrder: sortOrder, page: 1, hasNextPage: true);
  }

  void updateRange({
    required DateRangePreset preset,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final now = DateTime.now();
    final resolved = switch (preset) {
      DateRangePreset.thisMonth   => (start: _firstDayOfMonth(now), end: _lastDayOfMonth(now)),
      DateRangePreset.last3Months => (start: now.subtract(const Duration(days: 90)), end: now),
      DateRangePreset.lastYear    => (start: now.subtract(const Duration(days: 365)), end: now),
      DateRangePreset.custom      => (start: startDate, end: endDate),
    };
    state = state.copyWith(
      rangePreset: preset,
      startDate: resolved.start,
      endDate: resolved.end,
      page: 1,
      hasNextPage: true,
    );
  }

  void loadNextPage() {
    if (!state.hasNextPage || state.isLoadingMore) return;
    state = state.copyWith(page: state.page + 1, isLoadingMore: true);
  }

  void markPageLoaded({required bool hasMore}) {
    state = state.copyWith(isLoadingMore: false, hasNextPage: hasMore);
  }

  void reset() {
    state = build();
  }
}

final allTransactionsFilterNotifierProvider = NotifierProvider.autoDispose<
    AllTransactionsFilterNotifier, AllTransactionsFilter>(
  AllTransactionsFilterNotifier.new,
);
```

### `allTransactionsProvider`

The view uses an accumulated list pattern — the provider fetches one page at a time and the view appends to a local list maintained in `ConsumerStatefulWidget` state:

```dart
// Added to: lib/features/finances/presentation/providers/finances_providers.dart

/// Fetches a single page of transactions using the current filter state.
/// The view accumulates pages locally.
final allTransactionsPageProvider =
    FutureProvider.autoDispose<PaginatedTransactions>((ref) async {
  final filter = ref.watch(allTransactionsFilterNotifierProvider);
  final clubId = await ref.watch(currentClubIdProvider.future);
  if (clubId == null) throw Exception('Club no disponible');

  final repo = ref.read(financesRepositoryProvider);
  final result = await repo.getAllTransactions(
    clubId: clubId,
    page: filter.page,
    limit: 20,
    type: filter.type,
    search: filter.search,
    startDate: filter.startDate,
    endDate: filter.endDate,
    sortBy: filter.sortBy,
    sortOrder: filter.sortOrder,
  );

  return result.fold(
    (failure) => throw Exception(failure.message),
    (data) => data,
  );
});
```

### `PaginatedTransactions` Entity

```dart
// lib/features/finances/domain/entities/paginated_transactions.dart (NEW)

import 'package:equatable/equatable.dart';
import 'transaction.dart';

class PaginatedTransactions extends Equatable {
  final List<FinanceTransaction> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasNextPage;

  const PaginatedTransactions({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.hasNextPage,
  });

  @override
  List<Object?> get props => [items, page, limit, total, totalPages, hasNextPage];
}
```

### Accumulation Logic in `AllTransactionsView`

```dart
// Inside AllTransactionsView State:

List<FinanceTransaction> _accumulated = [];
int _lastLoadedPage = 0;

@override
void initState() {
  super.initState();
  _scrollController = ScrollController()..addListener(_onScroll);
  WidgetsBinding.instance.addPostFrameCallback((_) {
    ref.read(allTransactionsFilterNotifierProvider.notifier)
       .initWithMonth(widget.initialMonth);
  });
}

// In build — listen to provider changes:
ref.listen(allTransactionsPageProvider, (previous, next) {
  next.whenData((data) {
    if (data.page == 1) {
      // New filter applied — replace list
      setState(() {
        _accumulated = data.items;
        _lastLoadedPage = 1;
      });
    } else if (data.page > _lastLoadedPage) {
      // Next page loaded — append
      setState(() {
        _accumulated.addAll(data.items);
        _lastLoadedPage = data.page;
      });
    }
    ref.read(allTransactionsFilterNotifierProvider.notifier)
       .markPageLoaded(hasMore: data.hasNextPage);
  });
});
```

### Provider Dependency Map

```
allTransactionsPageProvider
  ├── watches: allTransactionsFilterNotifierProvider (filter + page)
  ├── watches: currentClubIdProvider (clubId)
  └── reads: financesRepositoryProvider

allTransactionsFilterNotifierProvider
  └── (standalone StateNotifier — no upstream deps)

currentClubIdProvider
  └── watches: clubContextProvider → auth context
```

---

## 11. Preserved Behavior

| Behavior | Source | Status |
|---|---|---|
| `TransactionTile` tap → `TransactionDetailView` | From `FinancesView` | Unchanged — same `SacSharedAxisRoute` push |
| FAB → `AddTransactionSheet` | From `FinancesView._openAddSheet` | Same `showModalBottomSheet` call, same sheet |
| Authorization via `canManageFinancesProvider` | `finances_providers.dart` | Same provider, no changes |
| Authorization via `financeMonthProvider.isOpen` | `finances_providers.dart` | FAB still respects open/closed period |
| `FinanceTransaction` entity structure | `transaction.dart` | No changes — same fields |
| `FinanceCategory` emoji mapping | `TransactionTile._emojiMap` | No changes — tile reused |
| `FinanceCategory` accent colors | `TransactionTile._accentColors` | No changes — tile reused |
| Amount formatting (`NumberFormat.currency`) | `TransactionTile` | No changes |
| Time formatting (`DateFormat('hh:mm a')`) | `TransactionTile` | No changes |
| Date group header formatting | `DateGroupHeader` | Extracted, same logic |
| `SacColorsExtension` semantic tokens | `sac_colors.dart` | No changes |
| `AppColors.primary` for FAB, buttons | `app_colors.dart` | No changes |

---

## 12. Files Affected

### New Files — Flutter

| File | Description |
|---|---|
| `lib/features/finances/presentation/views/all_transactions_view.dart` | Main screen — `ConsumerStatefulWidget`, coordinates all sub-components |
| `lib/features/finances/presentation/widgets/transaction_search_field.dart` | Debounced search input with clear button |
| `lib/features/finances/presentation/widgets/transaction_type_tabs.dart` | Segmented control for All / Income / Expense filtering |
| `lib/features/finances/presentation/widgets/sort_bottom_sheet.dart` | Sort options bottom sheet (date, amount, category + direction) |
| `lib/features/finances/presentation/widgets/range_bottom_sheet.dart` | Date range selector bottom sheet with custom date picker |
| `lib/features/finances/presentation/widgets/date_group_header.dart` | Extracted from `finances_view.dart` — shared between both list screens |
| `lib/features/finances/domain/entities/all_transactions_filter.dart` | Filter state value object + `DateRangePreset` enum |
| `lib/features/finances/domain/entities/paginated_transactions.dart` | Paginated response entity |

### Modified Files — Flutter

| File | Change |
|---|---|
| `lib/features/finances/presentation/views/finances_view.dart` | (1) Replace `_DateGroupHeader` private class with import of `DateGroupHeader`. (2) Wire `_openFullTransactionList` to push `AllTransactionsView` with `SacSharedAxisRoute`, passing `selectedMonthProvider` value. |
| `lib/features/finances/presentation/providers/finances_providers.dart` | Add `AllTransactionsFilterNotifier`, `allTransactionsFilterNotifierProvider`, `allTransactionsPageProvider` |
| `lib/features/finances/data/datasources/finances_remote_data_source.dart` | Add `getAllTransactions(...)` method to abstract class and `FinancesRemoteDataSourceImpl` |
| `lib/features/finances/domain/repositories/finances_repository.dart` | Add `getAllTransactions(...)` method signature to the abstract interface |
| `lib/features/finances/data/repositories/finances_repository_impl.dart` | Implement `getAllTransactions(...)` method, delegate to data source |

### New Files — Backend (NestJS)

| File | Description |
|---|---|
| `src/finances/dto/get-all-transactions.dto.ts` | DTO with `page`, `limit`, `type`, `search`, `startDate`, `endDate`, `sortBy`, `sortOrder` — all optional with validation decorators |

### Modified Files — Backend (NestJS)

| File | Change |
|---|---|
| `src/finances/finances.controller.ts` | Add `@Get(':clubId/transactions')` with `@Query() dto: GetAllTransactionsDto` |
| `src/finances/finances.service.ts` | Add `getAllTransactions(clubId: number, dto: GetAllTransactionsDto)` method with Prisma paginated query |

### Extracted (Refactored)

| From | To | Change |
|---|---|---|
| `finances_view.dart :: _DateGroupHeader` | `widgets/date_group_header.dart :: DateGroupHeader` | Class made public, file split, import updated in `finances_view.dart` |

---

## 13. Dependencies

### Existing Dependencies (no new packages required)

| Package | Usage in this screen |
|---|---|
| `flutter_riverpod` | `ConsumerStatefulWidget`, `FutureProvider`, `NotifierProvider`, `ref.listen`, `ref.watch` |
| `hugeicons` | Icons: `strokeRoundedSearch01`, `strokeRoundedCancel01`, `strokeRoundedSortByDown02`, `strokeRoundedCalendar03`, `strokeRoundedArrowUp01`, `strokeRoundedArrowDown01` |
| `intl` | `DateFormat`, `NumberFormat.currency` — same formatters as `TransactionTile` and `DateGroupHeader` |
| `equatable` | `AllTransactionsFilter`, `PaginatedTransactions` — for `==` and `hashCode` |
| `dio` | HTTP GET for the new paginated endpoint |

### Existing Core Utilities (no changes needed)

| Utility | Used for |
|---|---|
| `SacSharedAxisRoute` (`core/animations/page_transitions.dart`) | Screen push transition |
| `AppColors` (`core/theme/app_colors.dart`) | `AppColors.primary` for FAB, buttons, `RefreshIndicator` |
| `SacColorsExtension` / `SacColors` (`core/theme/sac_colors.dart`) | All semantic color tokens |
| `ApiEndpoints` (`core/constants/api_endpoints.dart`) | Base URL path for new endpoint |
| `ServerException`, `AuthException` (`core/errors/exceptions.dart`) | Error handling in data source |
| `AppLogger` (`core/utils/app_logger.dart`) | Logging in data source |
| `networkInfoProvider` (`providers/dio_provider.dart`) | Already used in `financesRepositoryImpl` — no changes |

### New Dart/Flutter APIs

| API | Reason |
|---|---|
| `ScrollController` | Infinite scroll detection (offset threshold) |
| `Timer` (dart:async) | 300ms debounce in `TransactionSearchField` |
| `showDatePicker` | Custom date range input in `RangeBottomSheet` |
| `AnimatedContainer` | Tab active state transition |
| `AnimatedSize` | Show/hide custom date fields in `RangeBottomSheet` |
| `RefreshIndicator` | Pull-to-refresh on the transaction list |

---

*End of specification. All implementation decisions above are approved and ready for the apply phase.*
