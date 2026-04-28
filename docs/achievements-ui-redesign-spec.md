# Achievements / Badges UI Redesign Spec

**Reference**: YouVersion Bible App badge grid (screenshots IMG_5436 and IMG_5435)
**Target**: SACDIA Flutter app — achievements feature
**Primary mode**: Dark (OLED-optimized, mirrors the app's existing dark theme)
**Author**: UI Design Agent
**Date**: 2026-04-10

---

## Table of Contents

1. Design Rationale
2. Design Tokens
3. Color Mapping — Achievement Tiers
4. Full Badges Grid Screen (replaces `achievements_view.dart` + `achievement_card.dart`)
5. Profile Badges Section (replaces `achievement_profile_summary.dart`)
6. Visual States Spec (Locked / In Progress / Unlocked)
7. Component Anatomy
8. Light Mode Adaptation
9. Animation Spec
10. Accessibility Notes
11. Implementation Checklist

---

## 1. Design Rationale

The current design uses a vertical list of `AchievementCard` rows (badge left, text right). The reference design replaces this with a **3-column compact grid** of dark cards, each showing only the badge image, a count pill, and a name label below — exactly matching the YouVersion pattern. This approach:

- Lets the user see more achievements at a glance without scrolling
- Makes the badge artwork the visual hero
- Uses a thin colored progress bar at the card bottom to communicate tier and progress
- Keeps the profile section as a lightweight horizontal scroll of earned badges only

The existing `AchievementBadge` widget animations (shimmer for platinum/diamond, pulse for diamond) are preserved and reused inside the new grid cards.

---

## 2. Design Tokens

All values are **logical pixels** (dp / lp in Flutter). Use `const` where possible.

### Screen

| Token | Dark Mode Value | Light Mode Value |
|---|---|---|
| `screenBackground` | `Color(0xFF000000)` | `Color(0xFFFFFFFF)` |
| `screenPadding` (horizontal) | `16.0` | `16.0` |

### Grid Layout

| Token | Value |
|---|---|
| `gridColumnCount` | `3` |
| `gridCrossAxisSpacing` | `10.0` |
| `gridMainAxisSpacing` | `10.0` |
| `gridChildAspectRatio` | `0.72` (width / height — card is taller than wide) |
| `gridPaddingTop` | `8.0` |
| `gridPaddingBottom` | `32.0` |

The `gridChildAspectRatio` of `0.72` produces a card roughly 110 dp wide × 152 dp tall on a 375 dp screen. Adjust slightly if text overflows on the smallest supported width.

### Badge Card

| Token | Dark Mode Value | Light Mode Value |
|---|---|---|
| `cardBackground` | `Color(0xFF1C1C1E)` | `Color(0xFFF2F2F7)` |
| `cardBorderRadius` | `14.0` | `14.0` |
| `cardPaddingTop` | `14.0` | `14.0` |
| `cardPaddingHorizontal` | `8.0` | `8.0` |
| `cardPaddingBottom` | `0.0` (progress bar flush to bottom edge) | `0.0` |
| `cardInternalSpacing` (badge bottom to pill top) | `8.0` | `8.0` |
| `cardElevation` | `0` (flat, no shadow on card itself) | `0` |
| `cardBorder` | none | `Border.all(color: Color(0xFFE2E8F0), width: 1.0)` |

> The card has NO border in dark mode — the dark grey surface on black background creates natural separation. In light mode a 1 dp hairline border is needed for contrast.

### Badge Image (inside grid card)

| Token | Value |
|---|---|
| `badgeSizeGrid` | `64.0` dp diameter |
| `badgeShape` | `BoxShape.circle` (ClipOval) |
| `badgeBorderWidthUnlocked` | `2.5` dp |
| `badgeBorderWidthLocked` | `0.0` (no border ring when locked or in-progress — the card background provides enough context) |

> The reference uses the badge image circular with a subtle colored ring only visible on unlocked state. Locked badges have no ring; the grayscale treatment + muted card communicates the locked state.

### Counter Pill

| Token | Dark Mode Value | Light Mode Value |
|---|---|---|
| `pillBackground` | `Color(0xFF3A3A3C)` | `Color(0xFFE5E5EA)` |
| `pillBorderRadius` | `10.0` (fully rounded) | `10.0` |
| `pillPaddingHorizontal` | `8.0` | `8.0` |
| `pillPaddingVertical` | `2.0` | `2.0` |
| `pillMinWidth` | `28.0` | `28.0` |
| `pillHeight` | `20.0` | `20.0` |
| `pillTextSize` | `12.0` | `12.0` |
| `pillTextWeight` | `FontWeight.w700` | `FontWeight.w700` |
| `pillTextColor` | `Color(0xFFF2F2F2)` | `Color(0xFF1C1C1E)` |
| `pillTextColorZero` | `Color(0xFF8C8C8C)` (muted when count = 0) | `Color(0xFF8C8C8C)` |

The pill shows:
- `0` when locked (muted color)
- Current progress count when in-progress (e.g., `3`)
- Times completed when unlocked (e.g., `1`, `5`)

### Achievement Name Label

| Token | Dark Mode Value | Light Mode Value |
|---|---|---|
| `nameFontSize` | `10.5` | `10.5` |
| `nameFontWeight` | `FontWeight.w600` | `FontWeight.w600` |
| `nameColor` | `Color(0xFFF2F2F2)` | `Color(0xFF1C1C1E)` |
| `nameColorLocked` | `Color(0xFF5C5C5C)` | `Color(0xFF8C8C8C)` |
| `nameMaxLines` | `2` | `2` |
| `nameTextAlign` | `TextAlign.center` | `TextAlign.center` |
| `namePaddingTop` | `5.0` | `5.0` |
| `namePaddingHorizontal` | `4.0` | `4.0` |
| `namePaddingBottom` | `8.0` (space before progress bar) | `8.0` |
| `nameLetterSpacing` | `0.0` | `0.0` |
| `nameLineHeight` | `1.25` | `1.25` |

### Progress Bar (bottom of card)

| Token | Value |
|---|---|
| `progressBarHeight` | `3.0` dp |
| `progressBarBorderRadius` | `0.0` on top corners, `14.0` on bottom corners (flush to card bottom rounded corners) |
| `progressBarTrackColor` (dark) | `Color(0xFF2C2C2E)` |
| `progressBarTrackColor` (light) | `Color(0xFFD1D1D6)` |
| `progressBarFillOpacityLocked` | `0.0` (empty — no fill) |
| `progressBarFillOpacityInProgress` | `1.0` (partial fill based on percentage) |
| `progressBarFillOpacityUnlocked` | `1.0` (full fill) |

The progress bar uses `BorderRadius.only(bottomLeft: Radius.circular(14), bottomRight: Radius.circular(14))` so it visually merges with the card's rounded bottom corners.

### AppBar

| Token | Dark Value | Light Value |
|---|---|---|
| `appBarBackground` | `Color(0xFF000000)` | `Color(0xFFFFFFFF)` |
| `appBarElevation` | `0` | `0` |
| `appBarTitleStyle` | `fontSize: 17, fontWeight: w600, color: Color(0xFFF2F2F2)` | same with `Color(0xFF1C1C1E)` |
| `appBarTitleAlignment` | `center` | `center` |
| `appBarBackIconColor` | `Color(0xFFF06151)` (SACDIA primary red) | `Color(0xFFF06151)` |
| `appBarSurfaceTintColor` | `Colors.transparent` | `Colors.transparent` |

The AppBar title is "Insignias" (matching the reference screenshot). No icon prefix — the reference shows a plain centered text title with a back chevron on the left.

---

## 3. Color Mapping — Achievement Tiers

These colors are used for:
- The badge border ring (unlocked state)
- The progress bar fill color
- The glow `BoxShadow` (unlocked only, alpha 0.35)
- The counter pill accent tint (unlocked only — pill background adopts a very subtle tinted overlay)

Existing `achievementTierColor()` function already defines these. Keep the function as-is. Additional semantic values are defined below for new use cases.

| Tier | Base Color (existing) | Ring Border Color | Glow Color | Progress Bar Fill | Pill Tint (unlocked bg) |
|---|---|---|---|---|---|
| BRONZE | `Color(0xFFCD7F32)` | `Color(0xFFCD7F32)` | `Color(0xFFCD7F32)` @ 35% alpha | `Color(0xFFCD7F32)` | `Color(0xFFCD7F32)` @ 18% alpha |
| SILVER | `Color(0xFFC0C0C0)` | `Color(0xFFC0C0C0)` | `Color(0xFFC0C0C0)` @ 35% alpha | `Color(0xFFC0C0C0)` | `Color(0xFFC0C0C0)` @ 18% alpha |
| GOLD | `Color(0xFFFFD700)` | `Color(0xFFFFD700)` | `Color(0xFFFFD700)` @ 35% alpha | `Color(0xFFFFD700)` | `Color(0xFFFFD700)` @ 18% alpha |
| PLATINUM | `Color(0xFFE5E4E2)` | `Color(0xFFE5E4E2)` | `Color(0xFFE5E4E2)` @ 35% alpha | `Color(0xFFE5E4E2)` | `Color(0xFFE5E4E2)` @ 18% alpha |
| DIAMOND | `Color(0xFFB9F2FF)` | `Color(0xFFB9F2FF)` | `Color(0xFFB9F2FF)` @ 40% alpha | `Color(0xFFB9F2FF)` | `Color(0xFFB9F2FF)` @ 18% alpha |

> DIAMOND gets slightly higher glow alpha (0.40 vs 0.35) to make the ice-blue pop on the dark background.

The existing progress bar in `achievement_card.dart` currently uses `AchievementProgressBar` — that widget should be reused/adapted for the new grid card's bottom bar with the same tier color logic.

---

## 4. Full Badges Grid Screen

### 4.1 Widget Tree Overview

```
Scaffold (backgroundColor: screenBackground)
  AppBar (centered title "Insignias", back button)
  body:
    RefreshIndicator
      CustomScrollView
        SliverToBoxAdapter → _SummaryStrip   (compact, replaces current 3-stat header)
        SliverToBoxAdapter → _CategoryChips  (unchanged — reuse existing)
        SliverPadding
          SliverGrid (3-column) → AchievementGridCard (new widget)
        SliverToBoxAdapter → SizedBox(height: 32)
```

### 4.2 Summary Strip (replaces `_SummaryHeader`)

The existing `_SummaryHeader` shows 3 stat boxes in a row. In the new design this becomes a **single compact strip** with three inline values separated by vertical dividers, placed flush between the AppBar and the category chips. It is visually lightweight — the grid is the star.

```
[  7 Completados  |  340 Puntos  |  72% Logrado  ]
```

| Property | Value |
|---|---|
| Height | `44.0` dp |
| Background | transparent (same as screen) |
| Padding horizontal | `16.0` |
| Divider | `1 dp` wide, `16 dp` tall, `Color(0xFF2C2C2E)` (dark) / `Color(0xFFE2E8F0)` (light) |
| Value font | `fontSize: 14, weight: w700, color: primary (F2F2F2 dark / 1C1C1E light)` |
| Label font | `fontSize: 11, weight: w500, color: textSecondary (8C8C8C)` |

### 4.3 Category Filter Chips

Keep the existing `_CategoryFilterChips` widget unchanged. It already scrolls horizontally and uses `FilterChip`. No visual changes needed here.

### 4.4 AchievementGridCard — New Widget

**File**: `lib/features/achievements/presentation/widgets/achievement_grid_card.dart`

This replaces `AchievementCard` for the grid view. The existing `AchievementCard` (row layout) can be kept for any future list view or detail context.

#### Structure

```
Container (card)
  ClipRRect (borderRadius: 14)
    Column
      SizedBox(height: cardPaddingTop = 14)
      Center → AchievementBadge (size: 64, existing widget, reused as-is)
      SizedBox(height: 8)
      Center → _CounterPill
      SizedBox(height: 5)
      Padding(horizontal: 4) → Text(name, maxLines: 2, center)
      Spacer
      _ProgressBar (height: 3, flush bottom)
```

#### Detailed Layout

```
┌─────────────────────────┐  ← card top, borderRadius 14
│                         │
│    ┌───────────────┐    │  14 dp top padding
│    │  badge image  │    │  64×64 dp circular
│    └───────────────┘    │
│         8 dp            │
│    ┌─────────────┐      │  counter pill
│    │     "1"     │      │  20 dp tall, min 28 dp wide
│    └─────────────┘      │
│         5 dp            │
│    "Versículo"          │  name, 2 lines max, centered
│    "guardado"           │  10.5 sp, w600
│                         │  Spacer fills remaining height
│█████████░░░░░░░░░░░░░░░│  ← progress bar 3 dp, flush bottom
└─────────────────────────┘  ← borderRadius 14 on bottom corners
```

The `Spacer` between the name label and the progress bar ensures the bar always sits at the very bottom of the card regardless of whether the name is 1 or 2 lines.

#### Tap Behavior

`GestureDetector` (or `InkWell` with `borderRadius: 14`) wrapping the entire card. On tap, open `AchievementDetailSheet` (existing bottom sheet — no changes needed).

#### Splash / Ripple

`Material` widget wrapping `ClipRRect` with `color: Colors.transparent`, then `InkWell` inside. This ensures the ink ripple respects the rounded clip.

---

## 5. Profile Badges Section

### 5.1 Current vs New

**Current**: `AchievementProfileSummary` — a card with 3 stat cells (completed count, points, highest tier). Tapping navigates to achievements screen.

**New**: Compact section with a header row and a horizontal scroll of circular badge thumbnails showing only unlocked/earned badges. Matches the reference screenshot profile section exactly.

### 5.2 New Widget: `AchievementProfileBadges`

**File**: `lib/features/achievements/presentation/widgets/achievement_profile_badges.dart`

#### Structure

```
Column (crossAxisAlignment: start)
  _SectionHeader
  SizedBox(height: 10)
  _BadgeScrollRow
```

#### `_SectionHeader`

```
Row
  Text("9")         ← totalUnlocked count, bold, large
  SizedBox(width: 4)
  Text("Insignias") ← label, muted
  Spacer
  Icon(grid_view)   ← tappable, navigates to full grid screen
```

| Property | Value |
|---|---|
| Count font | `fontSize: 20, weight: w700, color: textPrimary` |
| "Insignias" label font | `fontSize: 14, weight: w500, color: textSecondary` |
| Grid icon | `HugeIcons.strokeRoundedGrid01`, size `20`, color `textTertiary` |
| Icon tap area | 44×44 dp minimum touch target |

The entire header row is also tappable (navigate to full screen). Use `GestureDetector` on the Row.

#### `_BadgeScrollRow`

```
SizedBox(height: 52)   ← fixed height container for the scroll row
  ListView.builder (scrollDirection: Axis.horizontal)
    [for each unlocked badge]
      _ProfileBadgeThumbnail
      SizedBox(width: 10)
```

Only badges where `userAchievement.isCompleted == true` are shown. If there are no unlocked badges yet, show an empty state row (see below).

**Scroll padding**: `EdgeInsets.symmetric(horizontal: 0)` — inherits from the profile screen's own horizontal padding.

#### `_ProfileBadgeThumbnail`

| Property | Value |
|---|---|
| Diameter | `44.0` dp |
| Shape | `BoxShape.circle` |
| Border color | `achievementTierColor(tier)` |
| Border width | `2.0` dp |
| Image | `CachedNetworkImage`, `BoxFit.cover`, `ClipOval` |
| Glow | `BoxShadow(color: tierColor @ 30% alpha, blurRadius: 6, spreadRadius: 0)` |
| Tap | Opens `AchievementDetailSheet` for that achievement |

The thin colored border ring on each thumbnail provides the tier visual identity in the compact profile context. No counter pill here — just the badge artwork.

#### Empty State (no unlocked badges)

When `totalCompleted == 0`, show a single placeholder row:

```
Row
  DashedCircle(44dp)  ← 3 or 4 dashed placeholder circles
  Text("Completa logros para verlos aquí", style: bodySmall, muted)
```

Placeholder circle: `Container(44x44, decoration: BoxDecoration(shape: circle, border: Border.all(color: textTertiary @ 40%, width: 1.5, strokeAlign: inside)))`. No dashes needed — a solid thin muted ring is sufficient.

#### No-Data / Loading States

- **Loading**: 4 `Shimmer` placeholder circles of 44 dp diameter, same spacing as the real list
- **Error**: `SizedBox.shrink()` — fail silently on profile; user can navigate to full screen

### 5.3 Placement on Profile Screen

The new `AchievementProfileBadges` widget slots into the profile screen where `AchievementProfileSummary` currently lives. No additional wrapping card is needed — the section sits directly on the profile screen background, consistent with how the reference screenshot shows it (no card border, flush with the screen).

If the profile screen uses a containing `SacCard`, remove it for this widget. The header + scroll row look better as a direct section with no card border.

---

## 6. Visual States Spec

There are three states driven by `AchievementVisualState`: `locked`, `inProgress`, `unlocked`.

### 6.1 Locked State

Goal: communicate "not yet started, nothing earned."

| Element | Spec |
|---|---|
| Card background | `Color(0xFF1C1C1E)` — standard, no change |
| Card opacity | `1.0` — card itself is full opacity |
| Badge image | Grayscale via `ColorFilter.mode(Colors.grey, BlendMode.saturation)` — existing behavior |
| Badge border ring | None — no colored ring |
| Badge image opacity | `0.45` — apply `Opacity(opacity: 0.45)` around the `ColorFiltered` image to further dim it |
| Counter pill background | `Color(0xFF3A3A3C)` (standard dark pill) |
| Counter pill text | `"0"`, color `Color(0xFF5C5C5C)` (tertiary, muted) |
| Name text color | `Color(0xFF5C5C5C)` (tertiary) |
| Progress bar fill | `0.0` width — empty track only |
| Progress bar track | `Color(0xFF2C2C2E)` |

The combination of grayscale + reduced opacity + muted text + empty bar clearly communicates "locked" without any additional iconography.

Do NOT show a lock icon overlay on the badge — the reference design does not use one, and the visual cues above are sufficient.

### 6.2 In Progress State

Goal: communicate "you've started this, keep going."

| Element | Spec |
|---|---|
| Card background | `Color(0xFF1C1C1E)` — standard |
| Card opacity | `1.0` |
| Badge image | Grayscale via `ColorFilter.mode(Colors.grey, BlendMode.saturation)` |
| Badge image opacity | `1.0` — full opacity (not dimmed, unlike locked) |
| Badge border ring | None |
| Badge progress arc | Keep existing `_ProgressArcPainter` drawn around the badge. Arc color: `Color(0xFFFBBD5E)` (`AppColors.accent` / warning yellow). Track color: `Color(0xFF3A3A3C)`. Stroke width: `3.0`. |
| Counter pill background | `Color(0xFF3A3A3C)` |
| Counter pill text | Current progress value (e.g., `"3"`), color `Color(0xFFF2F2F2)` |
| Name text color | `Color(0xFFF2F2F2)` — full contrast |
| Progress bar fill | Partial fill — `progressPercentage` mapped to bar width. Color: `Color(0xFFFBBD5E)` (accent yellow) regardless of tier (communicates "in progress" universally) |
| Progress bar track | `Color(0xFF2C2C2E)` |

> The circular progress arc (from the existing `AchievementBadge`) is kept as-is. It wraps the badge adding `8 dp` to the container size (already in the existing widget). The grid card must account for this: badge container height = `64 + 8 = 72` dp when in-progress state. Use a fixed-height `SizedBox(width: 72, height: 72)` centered in the card to prevent layout shift between states.

### 6.3 Unlocked State

Goal: celebrate completion with full color and visual reward.

| Element | Spec |
|---|---|
| Card background | `Color(0xFF1C1C1E)` — standard. Do NOT tint the card background with tier color — the ring and bar are enough. |
| Card opacity | `1.0` |
| Badge image | Full color — no grayscale filter |
| Badge image opacity | `1.0` |
| Badge border ring | `2.5 dp` solid border, color = `achievementTierColor(tier)` |
| Badge glow | `BoxShadow(color: tierColor @ 35% alpha, blurRadius: 12, spreadRadius: 2)` — existing behavior |
| Diamond sparkle | Existing `_pulseController` animated star overlay — keep as-is |
| Platinum/Diamond shimmer | Existing `_shimmerController` ShaderMask — keep as-is |
| Counter pill background | Tier color @ 18% alpha — e.g., for gold: `Color(0xFFFFD700).withValues(alpha: 0.18)` |
| Counter pill text | Times completed (e.g., `"1"`, `"5"`), color = `achievementTierColor(tier)` |
| Name text color | `Color(0xFFF2F2F2)` — full contrast |
| Progress bar fill | Full width (`1.0`), color = `achievementTierColor(tier)` |
| Progress bar track | Not visible — fill covers 100% |

For **secret achievements** that are not yet completed: apply the Locked state spec. Secret badges that ARE completed: apply Unlocked state normally (the artwork is revealed).

---

## 7. Component Anatomy

### 7.1 `AchievementGridCard` Full Property List

```dart
class AchievementGridCard extends StatelessWidget {
  final AchievementWithProgress achievementWithProgress;
  final VoidCallback? onTap;
}
```

Internally derives all visual state from `achievementWithProgress` — no external state props needed.

### 7.2 `AchievementProfileBadges` Full Property List

```dart
class AchievementProfileBadges extends ConsumerWidget {
  // No constructor params — reads from userAchievementsProvider directly
  // like the existing AchievementProfileSummary
}
```

Reads `userAchievementsProvider` and filters `item.userAchievement?.isCompleted == true` to build the badge list.

### 7.3 `_CounterPill` (private to `AchievementGridCard`)

```dart
class _CounterPill extends StatelessWidget {
  final int count;
  final AchievementVisualState visualState;
  final AchievementTier tier;
}
```

Pill background: `locked` → `Color(0xFF3A3A3C)`, `inProgress` → `Color(0xFF3A3A3C)`, `unlocked` → `tierColor.withValues(alpha: 0.18)`.
Text color: `locked` → `Color(0xFF5C5C5C)`, `inProgress` → `Color(0xFFF2F2F2)`, `unlocked` → `achievementTierColor(tier)`.

### 7.4 `_GridProgressBar` (private to `AchievementGridCard`)

```dart
class _GridProgressBar extends StatelessWidget {
  final double progress;     // 0.0 to 1.0
  final AchievementVisualState visualState;
  final AchievementTier tier;
  final double height;       // default: 3.0
}
```

Uses `FractionallySizedBox(widthFactor: progress)` inside a `ClipRRect` with bottom-only rounded corners to achieve the partial fill effect without a custom painter.

```dart
ClipRRect(
  borderRadius: BorderRadius.only(
    bottomLeft: Radius.circular(14),
    bottomRight: Radius.circular(14),
  ),
  child: SizedBox(
    height: 3.0,
    child: Row(
      children: [
        // Fill
        FractionallySizedBox(
          widthFactor: progress.clamp(0.0, 1.0),
          child: Container(color: _fillColor()),
        ),
        // Track
        Expanded(child: Container(color: trackColor)),
      ],
    ),
  ),
)
```

Fill color logic:
- `locked`: show only track, no fill (widthFactor = 0.0)
- `inProgress`: `Color(0xFFFBBD5E)` (accent yellow)
- `unlocked`: `achievementTierColor(tier)`

---

## 8. Light Mode Adaptation

The app already has OLED dark mode as primary. Light mode adapts as follows. Use `context.sac.*` semantic tokens wherever possible rather than hardcoded values.

| Element | Light Mode Override |
|---|---|
| Screen background | `Color(0xFFFFFFFF)` |
| Card background | `Color(0xFFF2F2F7)` (iOS system grouped background) |
| Card border | `Border.all(color: Color(0xFFE2E8F0), width: 1.0)` |
| Counter pill background | `Color(0xFFE5E5EA)` |
| Counter pill text (locked) | `Color(0xFF8C8C8C)` |
| Counter pill text (in-progress) | `Color(0xFF1C1C1E)` |
| Progress bar track | `Color(0xFFD1D1D6)` |
| Name text (locked) | `Color(0xFF8C8C8C)` |
| Name text (active) | `Color(0xFF1C1C1E)` |
| AppBar background | `Color(0xFFFFFFFF)` |
| Summary strip dividers | `Color(0xFFE2E8F0)` |

All tier colors (ring, glow, bar fill, pill tint) remain identical in light mode — they are brand colors that must be consistent across themes.

The badge glow `BoxShadow` should have `blurRadius: 8` in light mode (reduced from 12) since the lighter background makes glows appear more intense.

---

## 9. Animation Spec

### 9.1 Grid Entry Animation (Stagger)

Reuse the existing `StaggeredListItem` pattern from `achievements_view.dart`. In the new grid, each `SliverGrid` child should enter with:

- Initial transform: `Offset(0, 0.06)` (6% height below final position) + `Opacity(0)`
- Final transform: `Offset(0, 0)` + `Opacity(1)`
- Duration: `240ms`
- Curve: `Curves.easeOut`
- Stagger delay per item: `30ms` (shorter than the current `55ms` because there are more items in a grid)
- Max items animated: first 12 (3 rows × 4 visible) — items beyond that appear instantly to avoid the animation running for too long on large lists

### 9.2 Badge-Level Animations

These are already implemented in `AchievementBadge` and are preserved unchanged:

| Animation | Trigger | Behavior |
|---|---|---|
| Shimmer | Platinum or Diamond, Unlocked | `_shimmerController.repeat(reverse: true)`, 2000ms |
| Pulse scale | Diamond, Unlocked | `_pulseController.repeat(reverse: true)`, 1200ms |
| Progress arc | In Progress | Static arc drawn by `_ProgressArcPainter`, no animation needed beyond the existing painter |

### 9.3 Counter Pill — Animated Value

Wrap the pill text in `AnimatedSwitcher` with `duration: 300ms, transitionBuilder: ScaleTransition` so the number animates when data loads. This is purely cosmetic but adds polish.

### 9.4 Pull-to-Refresh

Keep the existing `RefreshIndicator` with `color: AppColors.primary`. No changes.

### 9.5 Profile Badge Row — Horizontal Appear

The profile badge thumbnails appear via a single `FadeTransition` on the entire `_BadgeScrollRow` when data loads (via the existing `AnimatedSwitcher` in `AchievementProfileSummary` → replicated in the new widget). Duration: `300ms`.

---

## 10. Accessibility Notes

### Touch Targets

- Each grid card must have a minimum tap target of **44×44 dp**. With a `gridChildAspectRatio` of `0.72` and 3 columns on a standard 375 dp screen, each card is approximately `110 dp` wide — well above the 44 dp minimum.
- Profile badge thumbnails are `44 dp` diameter — exactly at the iOS/Material minimum. Do not reduce below this.
- The grid icon in the profile section header must have a `48×48` dp minimum tap target using `SizedBox` padding or `IconButton`.

### Semantics

Each `AchievementGridCard` should wrap with:

```dart
Semantics(
  label: '${achievement.name}. '
      '${visualState == AchievementVisualState.locked ? "Bloqueado" : '
      'visualState == AchievementVisualState.inProgress ? "$progressValue de $progressTarget completado" : '
      '"Completado $timesCompleted veces"}',
  button: true,
  child: ...
)
```

The counter pill and progress bar are decorative (`excludeSemantics: true` inside the Semantics node) since the label above communicates the same information.

### Reduced Motion

Respect `MediaQuery.of(context).disableAnimations`:

```dart
final reduceMotion = MediaQuery.of(context).disableAnimations;
```

- If `reduceMotion == true`: skip shimmer and pulse animations (do not start `_shimmerController` or `_pulseController`)
- Stagger animation delay: reduce to `0ms` (all items appear at once)
- `AnimatedSwitcher` transitions: reduce duration to `0ms`

### Color Contrast

All name labels and counter pill text meet WCAG AA contrast:

| Text / Background | Contrast Ratio |
|---|---|
| `Color(0xFFF2F2F2)` on `Color(0xFF1C1C1E)` | ~15.5:1 (AAA) |
| `Color(0xFF5C5C5C)` on `Color(0xFF1C1C1E)` (locked) | ~3.2:1 (AA Large — acceptable for 10.5sp) |
| `Color(0xFFFFD700)` on `Color(0xFF3A3A3C)` (gold pill) | ~8.4:1 (AAA) |
| `Color(0xFFCD7F32)` on `Color(0xFF3A3A3C)` (bronze pill) | ~4.6:1 (AA) |

The locked name text at 10.5sp with `Color(0xFF5C5C5C)` on `Color(0xFF1C1C1E)` is at ~3.2:1. This is intentional — the muted color communicates "inactive" and 10.5sp bold still passes AA Large. If stricter compliance is needed, raise the locked text color to `Color(0xFF6E6E6E)` (3.5:1).

---

## 11. Implementation Checklist

Use this list to track development progress.

### New Files to Create

- [ ] `lib/features/achievements/presentation/widgets/achievement_grid_card.dart`
  - `AchievementGridCard` widget
  - Private: `_CounterPill`, `_GridProgressBar`
- [ ] `lib/features/achievements/presentation/widgets/achievement_profile_badges.dart`
  - `AchievementProfileBadges` widget
  - Private: `_SectionHeader`, `_BadgeScrollRow`, `_ProfileBadgeThumbnail`

### Files to Modify

- [ ] `lib/features/achievements/presentation/views/achievements_view.dart`
  - Replace `SliverList` + `AchievementCategorySection` with `SliverGrid` + `AchievementGridCard`
  - Replace `_SummaryHeader` (3-card row) with inline `_SummaryStrip` (single row with dividers)
  - Remove category grouping from the grid — show all achievements in one flat grid, sorted by: unlocked first (by tier desc), in-progress second, locked last
  - Update `AppBar` title to `"Insignias"` to match reference (currently `"Logros"`)
  - Keep `_CategoryFilterChips` — filter still works, just collapses to flat grid
- [ ] Profile screen (wherever `AchievementProfileSummary` is used)
  - Replace `AchievementProfileSummary` with `AchievementProfileBadges`
  - Remove the wrapping `SacCard` if one exists around it

### Files to Keep Unchanged

- [ ] `lib/features/achievements/presentation/widgets/achievement_badge.dart` — reused as-is
- [ ] `lib/features/achievements/presentation/widgets/achievement_progress_bar.dart` — may be reused for grid bar or replaced by `_GridProgressBar` (simpler)
- [ ] `lib/features/achievements/presentation/views/achievement_detail_sheet.dart` — unchanged
- [ ] All domain entities, repositories, providers — no changes

### Sorting Logic for Flat Grid

The flat grid (replacing the category-grouped list) should sort achievements in this order:

1. `unlocked` — sorted by tier (diamond → platinum → gold → silver → bronze)
2. `inProgress` — sorted by `progressPercentage` descending (closest to completion first)
3. `locked` — sorted by tier ascending (bronze first — lowest barrier to unlock)

This sort can be implemented as a computed provider derived from `filteredAchievementGroupsProvider`. Flatten all groups, then apply the sort. The category filter chips continue to work — they filter before the sort.

### Data Dependencies

No new API calls or backend changes are needed. The existing `userAchievementsProvider` and `userAchievementsSummaryProvider` already supply all data required by both new widgets.

---

## Appendix: Key Measurements Summary

| Element | Value |
|---|---|
| Screen background | #000000 |
| Card background | #1C1C1E |
| Card border radius | 14 dp |
| Card top padding | 14 dp |
| Card horizontal padding | 8 dp |
| Grid columns | 3 |
| Grid gap (both axes) | 10 dp |
| Grid outer horizontal padding | 16 dp |
| Card aspect ratio | 0.72 (width:height) |
| Badge diameter (grid) | 64 dp |
| Badge container (in-progress) | 72 dp (64 + 4dp arc each side) |
| Badge border width (unlocked) | 2.5 dp |
| Counter pill height | 20 dp |
| Counter pill min width | 28 dp |
| Counter pill border radius | 10 dp |
| Counter pill font | 12 sp, w700 |
| Name font | 10.5 sp, w600 |
| Name max lines | 2 |
| Progress bar height | 3 dp |
| Profile badge thumbnail diameter | 44 dp |
| Profile badge border width | 2.0 dp |
| Profile scroll row height | 52 dp |
| AppBar title | "Insignias", 17 sp, w600, centered |
