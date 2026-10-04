# Finances Feature Redesign — Design Specification

**Date**: 2026-03-31
**Feature**: Finances (`sacdia-app/lib/features/finances/`)
**Status**: Approved — Ready for Implementation
**Author**: Design System / Mobile Team

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
9. [Chart Specifications](#9-chart-specifications)
10. [Preserved Behavior](#10-preserved-behavior)
11. [Files Affected](#11-files-affected)
12. [Dependencies](#12-dependencies)

---

## 1. Overview and Goals

### Summary

Complete visual redesign of the Finances screen in the SACDIA Flutter app. The goal is to fix an inconsistent visual hierarchy, modernize the interface using a dark-first finance app aesthetic (inspired by apps like Wells Fargo and Carbon), and introduce an area line chart that replaces the current custom bar chart.

The redesign preserves all existing business logic, Riverpod state management, navigation, and domain/data layers. It only touches presentation-layer files.

### Goals

- Fix the visual hierarchy so balance is the clear primary element
- Replace the bar chart with a more informative dual-line area chart
- Replace the `IncomeExpenseRow` chip block with a single inline summary sentence
- Redesign transaction tiles to use emoji category chips instead of icon containers
- Introduce a period selector (1M, 3M, 6M, 1A, Todo) that controls chart range
- Add a purple gradient FAB replacing the current extended FAB
- Maintain full light and dark mode support using existing `context.sac` tokens
- Keep code changes strictly inside the presentation layer

### Non-Goals

- No changes to domain entities, use cases, or repositories
- No changes to Riverpod providers (except what the period selector requires)
- No changes to navigation structure — single scrollable screen within SACDIA app
- No new backend endpoints

---

## 2. Design Decisions Summary

| Decision | Rationale |
|---|---|
| Single scrollable screen | Finances is a feature tab within the larger app. No internal bottom nav. |
| Replace bar chart with area line chart | Area chart conveys trend over time more clearly. Dual lines (income vs expense) on same axis are immediately comparable. |
| Remove `IncomeExpenseRow` chips | Two large chips take too much vertical space and duplicate chart info. A single inline sentence is more scannable. |
| Rewrite `BalanceHeaderCard` | Current card is a surfaced container with border/shadow. New design uses the full screen width, centered balance, no card border. |
| Emoji + category name chip | Replaces HugeIcon icon container. Cheaper to render, more expressive, and visually distinct per category. |
| Purple gradient FAB | Differentiates the add action from the primary SACDIA red brand color, giving it special visual weight. |
| `fl_chart` package | The existing bar chart is a `CustomPainter` without touch interaction. `fl_chart` provides bezier curves, gradient fills, and touch tooltips out of the box. |
| OLED dark background | `#000000` (true black) background in dark mode maximizes battery savings on AMOLED displays. Already used by `AppColors.darkBackground`. |

---

## 3. Screen Layout

### Scroll Structure (top to bottom)

```
┌─────────────────────────────────────────┐
│  SliverAppBar (pinned)                  │
│  "Finanzas"           [refresh icon]    │
├─────────────────────────────────────────┤
│                                         │
│         SALDO TOTAL                     │  ← label: uppercase, muted, ls 1.5px
│         $1,250.00                       │  ← 42px, weight 800, centered
│                                         │
│    ◀        Marzo 2026        ▶         │  ← month nav, centered row
│                                         │
│  Este mes: $800 ingresos y $550 egresos │  ← activity summary, centered
│                                         │
├── ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─┤  ← dashed separator
│                                         │
│  ┌─────────────────────────────────┐   │
│  │ Resumen del Mes   ● Ingresos    │   │  ← chart header + legend
│  │                   ● Egresos     │   │
│  │                                 │   │
│  │   $1.5K ─────────/──           │   │  ← area line chart
│  │   $1.0K ─── /──/   \──/─      │   │
│  │   $500  ─/──          \──      │   │
│  │   $0    ─────────────────────  │   │
│  │         1   7   14  21  28     │   │  ← X-axis labels
│  │                                 │   │
│  │   [1M]  3M   6M   1A  Todo     │   │  ← period selector chips
│  └─────────────────────────────────┘   │
│                                         │
├── ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─┤  ← dashed separator
│                                         │
│  Transacciones Recientes    Ver todo →  │  ← section header
│                                         │
│  Martes, 18 marzo                $250  │  ← date group header + daily total
│  ┌─────────────────────────────────┐   │
│  │ [🏠 Alquiler] Pago mensual      │   │  ← transaction item
│  │               -$250.00  08:21AM │   │
│  └─────────────────────────────────┘   │
│                                         │
│  Lunes, 17 marzo               $1,050  │
│  ┌─────────────────────────────────┐   │
│  │ [💰 Donación] Diezmos miembros  │   │
│  │               +$800.00  10:00AM │   │
│  └─────────────────────────────────┘   │
│  ┌─────────────────────────────────┐   │
│  │ [🛒 Compras]  Materiales evento │   │
│  │               -$250.00  14:30PM │   │
│  └─────────────────────────────────┘   │
│                                         │
│              Ver todas →                │  ← centered link
│                                         │
│                          ╭─────╮        │
│                          │  +  │        │  ← FAB (purple gradient)
│                          ╰─────╯        │
│                                         │
│  [80px bottom clearance for FAB]        │
└─────────────────────────────────────────┘
```

### Closed Period Banner Placement

When `financeMonth.isOpen == false`, the `ClosedPeriodBanner` is inserted between the dashed separator (after balance) and the chart section. No other layout changes.

```
│  [balance + month nav + summary text]   │
│                                         │
├── ─ ─ dashed separator ─ ─ ─ ─ ─ ─ ─ ─┤
│                                         │
│  ⚠ Este período está cerrado            │  ← ClosedPeriodBanner (unchanged)
│                                         │
│  [chart]                                │
```

---

## 4. Component Specifications

### 4.1 `BalanceHeaderCard` — REWRITE

**File**: `lib/features/finances/presentation/widgets/balance_header_card.dart`

**Description**: Simplified centered balance display. No card container, no border, no shadow. The balance lives directly on the screen background.

**Visual structure**:
```
         SALDO TOTAL
         $1,250.00
    ◀       Marzo 2026       ▶
```

**Layout spec**:

```
Container(
  padding: EdgeInsets.fromLTRB(24, 24, 24, 20),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      // "SALDO TOTAL" label
      Text("SALDO TOTAL")
        style: 11px, w600, letterSpacing 1.5, color: textTertiary

      SizedBox(height: 6)

      // Balance amount
      Text("$1,250.00")
        style: 42px, w800, letterSpacing -1.0, color: text

      SizedBox(height: 20)

      // Month navigation row
      Row(mainAxisAlignment: center)
        _NavChevron(left, disabled=false)
        SizedBox(width: 16)
        Text("Marzo 2026")
          style: 15px, w600, color: text
        SizedBox(width: 16)
        _NavChevron(right, disabled=isCurrentMonth)

      SizedBox(height: 14)

      // Activity summary text
      RichText(
        "Este mes: "         → color: textSecondary, 13px, w400
        "$800"               → color: incomeGreen, 13px, w700
        " ingresos y "       → color: textSecondary, 13px, w400
        "$550"               → color: expenseRed, 13px, w700
        " egresos"           → color: textSecondary, 13px, w400
      )
      textAlign: center
    ]
  )
)
```

**`_NavChevron` widget** (internal, replaces `_NavButton`):
- Size: 32x32
- Shape: circular (borderRadius full)
- Background: `surfaceVariant` (enabled) / `borderLight` (disabled)
- No border in the new design
- Icon: `HugeIcons.strokeRoundedArrowLeft01` / `ArrowRight01`, size 16
- Icon color: `text` (enabled) / `textTertiary` (disabled)
- `onTap: null` when disabled — no gesture

**Amount formatting**: Use `NumberFormat.currency(locale: 'es', symbol: '\$', decimalDigits: 2)`. Same as current implementation.

**Month label formatting**: Same `DateFormat('MMMM yyyy', 'es')` with first-letter uppercase. Same as current.

**Constructor**:
```dart
class BalanceHeaderCard extends ConsumerWidget {
  final FinanceMonth? financeMonth;
  final double? totalBalance;

  const BalanceHeaderCard({
    super.key,
    required this.financeMonth,
    this.totalBalance,
  });
```
Constructor signature unchanged. The `_PeriodBadge` is removed from this component. The open/closed period state is handled by the `ClosedPeriodBanner` which already exists.

---

### 4.2 `FinanceLineChart` — NEW (replaces `FinanceBarChart`)

**File**: `lib/features/finances/presentation/widgets/finance_line_chart.dart`

**Description**: Area line chart using `fl_chart`. Two overlaid lines: income (green) and expenses (red), each with a gradient area fill beneath. Includes a period selector row below the chart.

**Full component structure**:
```
Container (chart card)
  padding: 16px all sides
  borderRadius: 12px
  color: chartSurface (#0a0a0a dark / #FAFBFC light)
  margin: EdgeInsets.fromLTRB(16, 0, 16, 0)

  Column:
    // Header row
    Row(mainAxisAlignment: spaceBetween)
      Text("Resumen del Mes")   → 14px, w700, color: text
      Row:
        _ChartLegendDot(color: incomeGreen, label: "Ingresos")
        SizedBox(width: 12)
        _ChartLegendDot(color: expenseRed, label: "Egresos")

    SizedBox(height: 16)

    // Chart area
    SizedBox(
      height: 180,
      child: LineChart(...)
    )

    SizedBox(height: 12)

    // Period selector
    PeriodSelector(
      selected: currentPeriod,
      onChanged: (period) { ... }
    )
```

**Chart data model**: The chart receives daily data points. Each point is a `(dayIndex, amount)` pair where `dayIndex` is 1–31 for the 1M view. For longer periods, aggregation is done in the provider.

**Constructor**:
```dart
class FinanceLineChart extends ConsumerWidget {
  const FinanceLineChart({super.key});
```
It reads data from providers internally (reactive to `selectedMonthProvider` and the new `selectedPeriodProvider`).

**When data is empty**: Show a `_EmptyChartPlaceholder` widget (centered text "Sin datos para el período") instead of the chart. Same card container is preserved.

---

### 4.3 `PeriodSelector` — NEW

**File**: `lib/features/finances/presentation/widgets/period_selector.dart`

**Description**: A horizontal row of chips for selecting the chart period range.

**Periods**: `['1M', '3M', '6M', '1A', 'Todo']`

**Visual spec**:
```
Row(mainAxisAlignment: center)
  for each period:
    GestureDetector(
      onTap: () => onChanged(period),
      child: AnimatedContainer(
        duration: 200ms,
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 7)
        decoration: BoxDecoration(
          color: isActive
            ? (dark: #333333 / light: #0F172A)
            : Colors.transparent
          borderRadius: BorderRadius.circular(12)
        )
        child: Text(period)
          style: 10px
                 w600 if active, w400 if inactive
                 color: white if active
                         textTertiary if inactive
      )
    )
    SizedBox(width: 4)  // between chips
```

**Constructor**:
```dart
class PeriodSelector extends StatelessWidget {
  final String selected;        // '1M' | '3M' | '6M' | '1A' | 'Todo'
  final ValueChanged<String> onChanged;

  const PeriodSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });
```

**Provider integration**: `FinanceLineChart` reads/writes a new `selectedPeriodProvider` (a `StateProvider<String>`) initialized to `'1M'`. When the period changes, the chart's X-axis adapts (days for 1M, weeks for 3M, months for 6M/1A/Todo).

---

### 4.4 `TransactionTile` — REWRITE

**File**: `lib/features/finances/presentation/widgets/transaction_tile.dart`

**Description**: Card-style transaction row with an emoji category chip on the left, description in the middle, and amount + time on the right.

**Visual structure**:
```
InkWell (ripple, borderRadius 16)
  Container
    margin: symmetric(horizontal: 16, vertical: 4)
    padding: symmetric(horizontal: 14, vertical: 12)
    decoration:
      color: transactionSurface
        dark: #1A1A1A  |  light: #F8FAFC
      borderRadius: 16
      border (light mode only): 1px solid #F1F5F9
      NO box shadow

    Row:
      // Category chip
      _CategoryChip(category: transaction.category, isIncome: isIncome)
        Container
          padding: symmetric(horizontal: 10, vertical: 6)
          borderRadius: 12
          color: categoryAccentColor.withOpacity(0.13)
          child: Row:
            Text(emoji)        → 14px
            SizedBox(width: 4)
            Text(categoryName) → 12px, w600, color: categoryAccentColor

      SizedBox(width: 10)

      // Description column (Expanded)
      Expanded:
        Column(crossAxisAlignment: start):
          Text(description)   → 13px, w500, color: text, maxLines 1
          SizedBox(height: 2)
          Text(registeredByName) → 10px, w400, color: textTertiary, maxLines 1

      SizedBox(width: 8)

      // Amount + time column
      Column(crossAxisAlignment: end):
        Text("$sign$amount")  → 15px, w700
          color: incomeGreen (dark: #4FBF9F / light: #2D8A70) if income
                 expenseRed (#DC2626) if expense
        SizedBox(height: 2)
        Text("HH:mm · USD")   → 10px, w400, color: textTertiary
```

**Time formatting**: `DateFormat('hh:mm a').format(transaction.date.toLocal())` — e.g., "08:21 AM".

**Currency label**: Always `"USD"` (hardcoded for now; extensible if multi-currency is added later).

**Category chip emoji mapping** (maps `transaction.category.iconIndex` to an emoji):

| `iconIndex` | Emoji | Category label |
|---|---|---|
| 1 | 🛒 | Compras |
| 2 | 🏠 | Vivienda |
| 3 | 🚗 | Transporte |
| 4 | ⭐ | Favoritos |
| 5 | ❤️ | Salud |
| 6 | 📚 | Educación |
| 7 | 🎁 | Regalos |
| 8 | 💰 | Ingresos |
| 9 | 💼 | Trabajo |
| 10 | 🏷️ | Etiqueta |
| default | 💵 | Otros |

**Category chip accent color**: Use a fixed color palette keyed by `iconIndex` (not the income/expense color). This makes each category visually distinct regardless of transaction type.

| `iconIndex` | Accent color (hex) |
|---|---|
| 1 | `#F59E0B` (amber) |
| 2 | `#6366F1` (indigo) |
| 3 | `#3B82F6` (blue) |
| 4 | `#EC4899` (pink) |
| 5 | `#EF4444` (red) |
| 6 | `#8B5CF6` (violet) |
| 7 | `#F97316` (orange) |
| 8 | `#10B981` (emerald) |
| 9 | `#0EA5E9` (sky) |
| 10 | `#64748B` (slate) |
| default | `#6B7280` (gray) |

**Constructor**: Unchanged from current.
```dart
class TransactionTile extends StatelessWidget {
  final FinanceTransaction transaction;
  final VoidCallback? onTap;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.onTap,
  });
```

---

### 4.5 `IncomeExpenseRow` — REMOVE

**File**: `lib/features/finances/presentation/widgets/income_expense_row.dart`

**Action**: Delete the file. The income/expense summary is now an inline `RichText` sentence inside `BalanceHeaderCard`.

Do not delete the class until all references are removed from `finances_view.dart`.

---

### 4.6 `_DashedSeparator` — NEW (private widget in `finances_view.dart`)

**Description**: A horizontal dashed line used as a section separator.

**Spec**:
```dart
class _DashedSeparator extends StatelessWidget {
  // Uses CustomPainter to draw dashes
  // dashWidth: 5, dashGap: 4, strokeWidth: 1.5
  // color: dark #252525 / light #E2E8F0 (context.sac.border)
  // margin: EdgeInsets.symmetric(horizontal: 16, vertical: 20)
  // height: 1.5
}
```

Implementation note: Use a `CustomPainter` that iterates across the available width drawing `drawLine` segments with gaps. Alternatively, use a `Row` of small `Container` dashes (less clean). Prefer `CustomPainter`.

---

### 4.7 `_FinanceFab` — REWRITE (private widget in `finances_view.dart`)

**Current**: `FloatingActionButton.extended` with SACDIA red + "Agregar" label.

**New**: Circular `FloatingActionButton` with purple gradient and white "+" icon.

**Spec**:
```dart
class _AddFab extends StatelessWidget {
  final VoidCallback onTap;

  // Visual:
  // - 56x56 circular container
  // - gradient: LinearGradient(#9333EA → #7C3AED, begin: topLeft, end: bottomRight)
  // - shadow: [BoxShadow(color: Color(0x669333EA), blurRadius: 16, offset: Offset(0, 6))]
  // - icon: HugeIcons.strokeRoundedAdd01, size 24, color: white

  // Use FloatingActionButton with a Container child for the gradient,
  // or use a GestureDetector + Container if FAB styling is inflexible.
  // Preferred: FloatingActionButton(onPressed: onTap, backgroundColor: Colors.transparent,
  //   elevation: 0, child: Ink(decoration: BoxDecoration(gradient: ..., shape: circle)))
```

**Visibility logic**: Unchanged — `showFab = canManage && isOpen`.

---

### 4.8 `finances_view.dart` — MODIFY

**Changes**:
1. Remove `import` for `IncomeExpenseRow`, `FinanceBarChart`
2. Add `import` for `FinanceLineChart`, `PeriodSelector`, `_DashedSeparator`
3. Rewrite `_FinanceBody.build()` to use the new layout order
4. Rewrite `_AddFab` to use purple gradient
5. Replace the transactions section header to include "Ver todo" link
6. Add staggered list grouping by date with date headers

**New `_FinanceBody.build()` layout order**:
```dart
Column(children: [
  BalanceHeaderCard(...),           // balance + month nav + summary
  if (!isOpen) ClosedPeriodBanner(),
  _DashedSeparator(),
  FinanceLineChart(),               // line chart + period selector
  _DashedSeparator(),
  _TransactionsSectionHeader(),     // "Transacciones Recientes" + "Ver todo"
  if (transactions.isEmpty)
    _EmptyTransactions()
  else
    ..._buildGroupedTransactions(transactions),
  _VerTodoLink(),                   // centered link at the bottom of list
  SizedBox(height: 80),             // FAB clearance
])
```

**Grouped transactions builder** (`_buildGroupedTransactions`):
```
Input: List<FinanceTransaction> sorted by date descending
Output: List<Widget>

For each unique date:
  1. Emit _DateGroupHeader(date: date, dailyTotal: sum of that day's amounts)
  2. For each transaction on that date:
     Emit StaggeredListItem(index: globalIndex, child: TransactionTile(...))
```

**`_DateGroupHeader` spec**:
```
Padding(
  padding: EdgeInsets.fromLTRB(16, 12, 16, 6),
  child: Row(mainAxisAlignment: spaceBetween):
    Text(dateLabel)   → e.g. "Martes, 18 marzo"
      style: 11px, w600, color: textSecondary
      format: DateFormat('EEEE, d MMMM', 'es') with first-letter uppercase
    Text(dailyTotalFormatted)
      style: 11px, w600, color: textTertiary
      format: compact currency, no +/- sign
)
```

**`_VerTodoLink` spec**:
```
Padding(
  padding: EdgeInsets.symmetric(vertical: 16),
  child: Center(
    child: GestureDetector(
      onTap: () => _openFullTransactionList(context),
      child: Text("Ver todas las transacciones →")
        style: 13px, w500, color: textSecondary
        decoration: TextDecoration.underline
        decorationColor: textTertiary
    )
  )
)
```

**`_TransactionsSectionHeader` spec**:
```
Padding(
  padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
  child: Row(mainAxisAlignment: spaceBetween):
    Text("Transacciones Recientes")
      style: 15px, w700, color: text
    GestureDetector(
      onTap: () => _openFullTransactionList(context),
      child: Text("Ver todo →")
        style: 13px, w500, color: textTertiary
    )
)
```

---

## 5. Color and Theme Specifications

All colors are resolved via `context.sac` (the `SacColors` extension) unless they are finance-specific values that do not yet exist in the design system. Finance-specific colors are defined as constants in the relevant widget files.

### 5.1 Base Palette

| Token | Dark | Light | Description |
|---|---|---|---|
| `context.sac.background` | `#000000` | `#FFFFFF` | Screen background |
| `context.sac.surface` | `#1A1A1A` | `#FFFFFF` | Card/surface |
| `context.sac.surfaceVariant` | `#252525` | `#F8FAFC` | Alt surface |
| `context.sac.border` | `#303030` | `#E2E8F0` | Card border |
| `context.sac.borderLight` | `#252525` | `#F1F5F9` | Subtle border |
| `context.sac.text` | `#F2F2F2` | `#0F172A` | Primary text |
| `context.sac.textSecondary` | `#8C8C8C` | `#64748B` | Secondary text |
| `context.sac.textTertiary` | `#5C5C5C` | `#94A3B8` | Metadata, hints |

### 5.2 Finance-Specific Colors

These are not in `SacColors` yet. Define them as local constants in the affected widgets, or add to `SacColors` in a follow-up refactor.

| Name | Dark | Light | Usage |
|---|---|---|---|
| `incomeGreen` | `#4FBF9F` | `#2D8A70` | Income amounts, chart income line |
| `expenseRed` | `#DC2626` | `#DC2626` | Expense amounts, chart expense line |
| `chartSurface` | `#0A0A0A` | `#FAFBFC` | Chart container background |
| `transactionSurface` | `#1A1A1A` | `#F8FAFC` | Transaction tile background |
| `transactionBorder` | none | `#F1F5F9` | Transaction tile border (light only) |
| `fabGradientStart` | `#9333EA` | `#9333EA` | FAB gradient start |
| `fabGradientEnd` | `#7C3AED` | `#7C3AED` | FAB gradient end |
| `fabShadow` | `#9333EA` @ 40% | `#9333EA` @ 40% | FAB glow shadow |
| `periodActiveBackground` | `#333333` | `#0F172A` | Active period chip background |
| `periodActiveText` | `#FFFFFF` | `#FFFFFF` | Active period chip text |
| `dashedSeparator` | `#252525` | `#E2E8F0` | Dashed separator line color |

### 5.3 Chart Line Colors

| Element | Color | Notes |
|---|---|---|
| Income line stroke | `#4FBF9F` | Always — no mode change |
| Income area fill start | `#4FBF9F` @ 30% opacity | Top of gradient |
| Income area fill end | `#4FBF9F` @ 0% opacity | Bottom of gradient (transparent) |
| Expense line stroke | `#DC2626` | Always |
| Expense area fill start | `#DC2626` @ 25% opacity | Top of gradient |
| Expense area fill end | `#DC2626` @ 0% opacity | Bottom of gradient (transparent) |
| Grid lines | dark: white @ 5% / light: black @ 6% | Subtle horizontal grid |
| Active dot | stroke `#FFFFFF` @ 100%, fill = line color | Touch highlight |

---

## 6. Typography Scale

All values use the system font stack (the Flutter default which maps to SF Pro on iOS and Roboto on Android). No custom font import is needed.

| Element | Size | Weight | Letter-spacing | Color token |
|---|---|---|---|---|
| Balance label ("SALDO TOTAL") | 11px | 600 | 1.5px | `textTertiary` |
| Balance amount | 42px | 800 | -1.0px | `text` |
| Month nav label | 15px | 600 | 0.2px | `text` |
| Activity summary base text | 13px | 400 | 0 | `textSecondary` |
| Activity summary income amount | 13px | 700 | 0 | `incomeGreen` |
| Activity summary expense amount | 13px | 700 | 0 | `expenseRed` |
| Chart section title | 14px | 700 | 0 | `text` |
| Chart legend label | 11px | 500 | 0 | `textSecondary` |
| Chart Y-axis labels | 10px | 400 | 0 | `textTertiary` |
| Chart X-axis labels | 10px | 400 | 0 | `textTertiary` |
| Period chip (active) | 10px | 600 | 0 | white |
| Period chip (inactive) | 10px | 400 | 0 | `textTertiary` |
| Section header title | 15px | 700 | 0 | `text` |
| Section header "Ver todo" | 13px | 500 | 0 | `textTertiary` |
| Date group header | 11px | 600 | 0 | `textSecondary` |
| Date group daily total | 11px | 600 | 0 | `textTertiary` |
| Transaction description | 13px | 500 | 0 | `text` |
| Transaction registered-by | 10px | 400 | 0 | `textTertiary` |
| Transaction amount | 15px | 700 | 0 | `incomeGreen` or `expenseRed` |
| Transaction time + currency | 10px | 400 | 0 | `textTertiary` |
| Category chip name | 12px | 600 | 0 | category accent color |
| Category chip emoji | 14px | 400 | 0 | (emoji, no color applied) |
| "Ver todas" link | 13px | 500 | 0 | `textSecondary` |
| Empty state title | 14px (titleSmall) | 600 | 0 | `textSecondary` |
| Empty state body | 12px (bodySmall) | 400 | 0 | `textTertiary` |

---

## 7. Spacing and Radius Tokens

### Radius

| Token | Value | Used on |
|---|---|---|
| `radiusCard` | 16px | Transaction tiles |
| `radiusChart` | 12px | Chart container |
| `radiusChip` | 12px | Category chips, period selector chips |
| `radiusChevron` | 50% (full) | Month nav chevron buttons |
| `radiusFab` | 50% (full) | FAB |

### Spacing

| Location | Value |
|---|---|
| Screen horizontal padding | 16px (applied per widget, not at screen level) |
| Balance section vertical padding | top: 24px, bottom: 20px |
| Between balance label and amount | 6px |
| Between amount and month nav | 20px |
| Between month nav and activity summary | 14px |
| Dashed separator vertical margin | 20px top + 20px bottom (40px total gap) |
| Chart container padding (internal) | 16px all sides |
| Chart container horizontal margin | 16px left + 16px right |
| Between chart header and chart area | 16px |
| Between chart area and period selector | 12px |
| Between section header and first group | 8px |
| Between date group header and first tile | 0px (header has 12px top, 6px bottom) |
| Between transaction tiles | 8px (via vertical margin 4px top + 4px bottom) |
| Transaction tile internal padding | 12px vertical, 14px horizontal |
| Between category chip and description | 10px |
| Between description and amount column | 8px |
| Bottom FAB clearance | 80px |

---

## 8. Interaction and Animation Specs

### Month Navigation

- **Tap left arrow**: calls `ref.read(selectedMonthProvider.notifier).goToPrevious()`
- **Tap right arrow**: calls `ref.read(selectedMonthProvider.notifier).goToNext()` — only if `!selected.isCurrentMonth`
- **Right arrow disabled state**: `onTap: null`, opacity 0.4 on icon
- **Effect**: Both chart and transaction list react because they read `selectedMonthProvider` via their own providers
- **No animation on content transition** — data loads via `AsyncValue` state, loading skeletons handle the transition

### Period Selector

- **Tap chip**: Updates `selectedPeriodProvider` state
- **Chip transition**: `AnimatedContainer` with duration 200ms for background color change
- **Text weight change**: immediate (no animation needed — `TextStyle` is rebuilt)
- **Chart update**: `FinanceLineChart` reads `selectedPeriodProvider` and rebuilds with new X-axis range

### Chart Touch Interaction

- **Single tap on chart area**: Shows `fl_chart` `LineTouchData` tooltip
- **Tooltip appearance**: Small floating label showing the tapped point value
  - Background: dark `#1A1A1A` / light `#FFFFFF`
  - Border: `border` color token, 1px
  - Radius: 8px
  - Text: 12px, w600, color matches line color (green or red)
  - Format: currency compact (e.g., `$1.2K`)
- **Touch indicator**: Vertical dashed line at the touched X position, `border` color, 1px wide

### Transaction Tap

- `InkWell` ripple with `borderRadius: BorderRadius.circular(16)` — matches tile radius
- On tap: navigate via `SacSharedAxisRoute` to `TransactionDetailView(transaction: t)`
- No changes to navigation logic

### "Ver todo" Link

- `GestureDetector` with immediate navigation on tap
- No ripple effect (it is a text link, not a card)
- Navigate to the full transaction list view (existing route — behavior unchanged)

### Staggered List Animation

- Use existing `StaggeredListItem` widget wrapping each `TransactionTile`
- Index is the global index across all groups (not resetting per group)
- The `_DateGroupHeader` widgets are NOT wrapped in `StaggeredListItem` — they appear instantly

### FAB

- Standard `FloatingActionButton` elevation and press behavior
- On tap: `_openAddSheet(context, ref)` — unchanged from current

### Pull-to-Refresh

- `RefreshIndicator` unchanged
- `color: AppColors.primary` (SACDIA red) — unchanged
- `onRefresh` callback: `ref.invalidate(financeMonthProvider)` + `ref.invalidate(financeSummaryProvider)` — unchanged

---

## 9. Chart Specifications

### Library

**Package**: `fl_chart: ^0.69.0` (or latest stable)
**Import**: `import 'package:fl_chart/fl_chart.dart';`

### Data Model

The chart renders two `LineChartBarData` entries:
- `incomeSpots`: `List<FlSpot>` — `(dayIndex, incomeAmount)`
- `expenseSpots`: `List<FlSpot>` — `(dayIndex, expenseAmount)`

For the `1M` period, `dayIndex` is the day of month (1–31). For `3M`, it is weeks since start. For `6M` and `1A`, it is month index. For `Todo`, it is month index across all available data.

Data sourcing: The existing `financeSummaryProvider` already provides `MonthlyBar` data. A new provider `chartDataProvider` should derive the `FlSpot` lists from the existing data, filtered by the `selectedPeriodProvider`. This is a presentation-layer derived provider — no backend calls needed beyond what already exists.

### `LineChartData` Configuration

```dart
LineChartData(
  // Grid
  gridData: FlGridData(
    show: true,
    drawVerticalLine: false,
    drawHorizontalLine: true,
    horizontalInterval: maxValue / 3,   // 3 horizontal grid lines
    getDrawingHorizontalLine: (value) => FlLine(
      color: isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.06),
      strokeWidth: 1,
      dashArray: null,   // solid grid lines
    ),
  ),

  // Axes
  titlesData: FlTitlesData(
    leftTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 40,
        interval: maxValue / 3,
        getTitlesWidget: (value, meta) => Text(
          _formatAxisValue(value),  // e.g., "$1K", "$500", "$0"
          style: TextStyle(fontSize: 10, color: textTertiary),
        ),
      ),
    ),
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 20,
        interval: _bottomInterval(period),  // 7 for 1M, 1 for 3M+
        getTitlesWidget: (value, meta) => Text(
          _formatBottomLabel(value, period),  // e.g., "14", "Sem 2", "Mar"
          style: TextStyle(fontSize: 10, color: textTertiary),
        ),
      ),
    ),
    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
  ),

  // Border
  borderData: FlBorderData(show: false),

  // Touch
  lineTouchData: LineTouchData(
    enabled: true,
    touchTooltipData: LineTouchTooltipData(
      tooltipBgColor: isDark ? Color(0xFF1A1A1A) : Colors.white,
      tooltipBorder: BorderSide(color: borderColor, width: 1),
      tooltipRoundedRadius: 8,
      getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
        final isIncome = spot.barIndex == 0;
        return LineTooltipItem(
          _formatTooltipValue(spot.y),
          TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isIncome ? incomeGreen : expenseRed,
          ),
        );
      }).toList(),
    ),
    getTouchedSpotIndicator: (barData, spotIndexes) =>
      spotIndexes.map((_) => TouchedSpotIndicatorData(
        FlLine(color: borderColor, strokeWidth: 1, dashArray: [4, 4]),
        FlDotData(
          getDotPainter: (spot, percent, barData, index) =>
            FlDotCirclePainter(
              radius: 5,
              color: barData.color!,
              strokeWidth: 2,
              strokeColor: Colors.white,
            ),
        ),
      )).toList(),
  ),

  // Lines
  lineBarsData: [
    // Income line (index 0)
    LineChartBarData(
      spots: incomeSpots,
      isCurved: true,
      curveSmoothness: 0.35,
      color: Color(0xFF4FBF9F),
      barWidth: 2.5,
      isStrokeCapRound: true,
      dotData: FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF4FBF9F).withValues(alpha: 0.30),
            Color(0xFF4FBF9F).withValues(alpha: 0.00),
          ],
        ),
      ),
    ),
    // Expense line (index 1)
    LineChartBarData(
      spots: expenseSpots,
      isCurved: true,
      curveSmoothness: 0.35,
      color: Color(0xFFDC2626),
      barWidth: 2.5,
      isStrokeCapRound: true,
      dotData: FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFDC2626).withValues(alpha: 0.25),
            Color(0xFFDC2626).withValues(alpha: 0.00),
          ],
        ),
      ),
    ),
  ],

  // Min/Max
  minX: 1,
  maxX: _maxX(period),    // 31 for 1M, 12 for 3M (weeks), etc.
  minY: 0,
  maxY: maxValue * 1.15,  // 15% headroom above max value
)
```

### Axis Label Formatting

**Y-axis** (`_formatAxisValue`):
```
>= 1000  → "$Xk" (e.g., "$1.5K")
>= 100   → "$X"  (e.g., "$500")
== 0     → "$0"
```

**X-axis** (`_formatBottomLabel`):

| Period | Label format | Example |
|---|---|---|
| `1M` | Day number | `"1"`, `"7"`, `"14"`, `"21"`, `"28"` |
| `3M` | Short week label | `"S1"`, `"S2"`, `"S3"` ... |
| `6M` | Short month abbreviation | `"Ene"`, `"Feb"` ... |
| `1A` | Short month abbreviation | `"Ene"`, `"Feb"` ... |
| `Todo` | Year or short month+year | `"Mar 25"`, `"Abr 25"` ... |

### X-Axis Interval by Period

| Period | `bottomInterval` |
|---|---|
| `1M` | 7.0 (shows days 1, 7, 14, 21, 28) |
| `3M` | 1.0 (each week marker) |
| `6M` | 1.0 (each month) |
| `1A` | 1.0 (each month) |
| `Todo` | 1.0 (each available month) |

### Empty Chart State

When `incomeSpots.isEmpty && expenseSpots.isEmpty`:
```
Container(
  height: 180,
  alignment: Alignment.center,
  child: Text("Sin datos para el período")
    style: 13px, w400, color: textTertiary
)
```

---

## 10. Preserved Behavior

The following must not change under any circumstances:

| Behavior | Location | Notes |
|---|---|---|
| Month navigation | `selectedMonthProvider` notifier | `goToPrevious()`, `goToNext()` |
| Future month disabled | `!selected.isCurrentMonth` check | Right arrow becomes `null` onTap |
| Pull-to-refresh | `RefreshIndicator` + `ref.invalidate` | Both `financeMonthProvider` and `financeSummaryProvider` |
| FAB visibility | `showFab = canManage && isOpen` | Both conditions required |
| FAB action | `_openAddSheet` → `AddTransactionSheet` modal | `isScrollControlled: true` |
| Closed period banner | `ClosedPeriodBanner` | Shown when `!isOpen` |
| Transaction tap | `SacSharedAxisRoute` → `TransactionDetailView` | Shared axis page transition |
| Staggered list animation | `StaggeredListItem` wrapper | Index-based delay |
| Refresh icon in AppBar | When loading: spinner; when loaded: button | Existing logic |
| Authorization check | `canManageFinancesProvider` | No change |
| Error state | `_ErrorBody` widget | No change |
| Loading state | `_LoadingBody` widget | May update skeleton visuals to match new layout |
| Domain + data layers | Everything under `domain/` and `data/` | Zero changes |
| All Riverpod providers | `finances_providers.dart` | Only additions allowed (e.g., `selectedPeriodProvider`) |

---

## 11. Files Affected

### Modified

| File | Change |
|---|---|
| `lib/features/finances/presentation/views/finances_view.dart` | New layout, new FAB, grouped transactions, section headers |
| `lib/features/finances/presentation/widgets/balance_header_card.dart` | Full rewrite — centered balance, no card container |
| `lib/features/finances/presentation/widgets/transaction_tile.dart` | Full rewrite — emoji category chip layout |

### New

| File | Description |
|---|---|
| `lib/features/finances/presentation/widgets/finance_line_chart.dart` | Area line chart with `fl_chart` |
| `lib/features/finances/presentation/widgets/period_selector.dart` | Period chip row (1M, 3M, 6M, 1A, Todo) |

### Deleted

| File | Replacement |
|---|---|
| `lib/features/finances/presentation/widgets/finance_bar_chart.dart` | `finance_line_chart.dart` |
| `lib/features/finances/presentation/widgets/income_expense_row.dart` | Inline `RichText` in `BalanceHeaderCard` |

### Untouched (do not modify)

```
lib/features/finances/domain/entities/
lib/features/finances/domain/repositories/
lib/features/finances/data/
lib/features/finances/presentation/providers/finances_providers.dart
lib/features/finances/presentation/views/add_transaction_sheet.dart
lib/features/finances/presentation/views/transaction_detail_view.dart
lib/features/finances/presentation/widgets/closed_period_banner.dart
lib/core/theme/app_colors.dart
lib/core/theme/sac_colors.dart
```

---

## 12. Dependencies

### New Package

**`fl_chart`**

```yaml
# pubspec.yaml
dependencies:
  fl_chart: ^0.69.0
```

Run `flutter pub get` after adding.

**Why `fl_chart` over a custom `CustomPainter`**:

| Criterion | `fl_chart` | Custom `CustomPainter` |
|---|---|---|
| Bezier curves | Built-in (`isCurved: true`) | Manual math required |
| Gradient area fills | Built-in (`belowBarData`) | Manual shader setup |
| Touch tooltips | Built-in (`LineTouchData`) | Gesture detection + custom overlay |
| Maintenance burden | Library maintained | All yours |
| Bundle size impact | ~180KB compressed | ~0KB |
| Customization | Sufficient for this use case | Unlimited |

The current `FinanceBarChart` uses `CustomPainter` but has no touch interaction. The redesign adds touch tooltips and animated transitions that would require significant custom code. `fl_chart` is the pragmatic choice.

**`fl_chart` minimum Flutter version**: Flutter 3.0 — compatible with this project.

### No Other New Packages Required

| Functionality | Solution |
|---|---|
| Emoji display | Plain `Text` widget (Flutter renders emoji natively) |
| Dashed separator | `CustomPainter` (no external package needed) |
| Gradient FAB | `Ink` + `BoxDecoration` gradient inside `FloatingActionButton` |
| Date formatting | `intl` package (already in `pubspec.yaml`) |
| Currency formatting | `intl` package (already in `pubspec.yaml`) |

---

*End of specification.*
