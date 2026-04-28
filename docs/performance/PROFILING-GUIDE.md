# sacdia-app — iOS Performance Profiling Guide

**Target**: App Store submission (sacdia-app v1.0.0+1)  
**Stack**: Flutter 3.x, Riverpod, Dio, SharedPreferences, Firebase, Google Maps  
**Last updated**: April 2026  

---

## Table of Contents

1. [Apple's Performance Criteria](#part-1-apples-performance-criteria)
2. [Xcode Instruments Profiling](#part-2-xcode-instruments-profiling)
3. [Flutter DevTools Profiling](#part-3-flutter-devtools-profiling)
4. [Automated Performance Testing](#part-4-automated-performance-testing)
5. [Pre-Submission Checklist](#part-5-pre-submission-checklist)

---

## Part 1: Apple's Performance Criteria

### 1.1 MetricKit Thresholds

Apple's MetricKit collects diagnostics from real user devices. These are the specific numeric thresholds you must not exceed. Metrics are reported in Xcode Organizer under **Metrics > [your app]**.

| Metric | Apple Threshold | Sacdia Target | Failure Consequence |
|--------|----------------|---------------|---------------------|
| Cold launch (time to first frame) | < 400 ms P50, < 2000 ms P90 | < 350 ms P50 | Watchdog kill at 20 s; App Store rejection if consistently > 2 s |
| Warm launch | < 200 ms P50 | < 150 ms P50 | User-visible lag on app switches |
| Main thread hang rate | < 50 ms/s | < 10 ms/s | Watchdog kill at 8 s foreground hang |
| Memory at peak | < 200 MB for 2 GB devices | < 150 MB | jetsam kill; iOS kills at 50 %+ of RAM |
| Disk writes per day | < 1 GB / 24 h | < 100 MB / 24 h | Review flag for excessive I/O |
| CPU time / foreground | < 20 % sustained | < 15 % sustained | Battery drain; thermal throttle |
| Battery usage per hour (foreground) | < 4 % | < 3 % | Appears in iOS battery settings as high |
| Hang rate (cumulative) | < 1 hang / 1000 s | < 0.5 hangs / 1000 s | App Store badge "Poor Responsiveness" |

### 1.2 App Store Review Performance Rejection Reasons

Apple's review team uses real devices (iPhone 14/15 class hardware) on low-power mode to stress test. These are documented rejection reasons:

- **Guideline 2.1 — App Completeness**: crash on launch or within first 3 taps
- **Guideline 4.2 — Minimum Functionality**: loading screen > 5 s with no content
- **Guideline 4.0 — Design / Performance**: UI freeze > 3 s during normal navigation
- **Excessive battery drain** reported during review (no official threshold, but > 10 %/hr is flagged)
- **Memory crash on 3 GB device** — jetsam kills above ~1.5 GB are automatic rejections

The review process also runs automated MetricKit analysis via App Store Connect. If your Xcode Organizer shows red in any P90 metric, you will fail this check before human review.

### 1.3 Xcode Organizer Metrics

Open Xcode → Window → Organizer → Metrics tab. The columns map to:

- **Launch Time**: `MXAppLaunchMetric` — time from `application(_:didFinishLaunchingWithOptions:)` to first CA commit
- **Hang Rate**: `MXHangDiagnostic` — main thread blocked > 250 ms
- **Memory**: `MXMemoryMetric` — peak and average physical memory footprint
- **Disk Writes**: `MXDiskIOCounterMetric` — cumulative writes per day
- **CPU Time**: `MXCPUMetric` — foreground + background CPU seconds

Percentiles to focus on: P50 (median experience), P90 (worst 10 %), P99 (edge cases). Apple flags you when your P90 exceeds their thresholds.

### 1.4 iOS Watchdog Kill Thresholds

The iOS watchdog (`com.apple.runningboard`) sends `SIGKILL` when:

| Scenario | Kill timeout |
|----------|-------------|
| Launch not complete (no first frame) | 20 seconds |
| Main thread not responsive in foreground | 8 seconds |
| Background task not completed | 30 seconds (BGTask) |
| `UIApplicationDelegate.applicationDidFinishLaunching` return | Must return before 20 s |

Flutter-specific risk: `WidgetsFlutterBinding.ensureInitialized()` + Firebase init + SharedPreferences all happen synchronously on the platform thread before the first frame. In sacdia-app's `main()`, you are already parallelizing orientation and SharedPreferences with `Future.wait`, which is correct. Firebase must still be awaited before `runApp`.

---

## Part 2: Xcode Instruments Profiling

### Prerequisites

```bash
# Verify Instruments is installed
xcrun instruments -s templates

# Build sacdia-app in profile mode (NOT debug — debug disables JIT optimizations)
cd /Users/abner/Documents/development/sacdia/sacdia-app
flutter build ios --profile --no-codesign

# Open the Runner.xcworkspace
open ios/Runner.xcworkspace
```

In Xcode: set the scheme to **Profile** (not Debug). Product > Scheme > Edit Scheme > Profile > Build Configuration = Profile.

### 2.1 App Launch — Time Profiler

**Goal**: Measure cold and warm launch time and identify what runs on the main thread before the first frame.

#### Setup

1. Open Instruments (Xcode > Open Developer Tool > Instruments)
2. Choose template: **App Launch** (combines Time Profiler + System Trace)
3. Select target: your connected device (NOT simulator — launch metrics on simulator are meaningless)
4. Set recording time: 10 seconds

#### Procedure — Cold Launch

```
1. Kill sacdia-app completely on device (swipe up in App Switcher)
2. Press Record in Instruments
3. App launches automatically — do NOT touch the device until the home screen fully renders
4. Press Stop after the loading screen disappears
```

#### Procedure — Warm Launch

```
1. Press Home button (do NOT kill the app)
2. Wait 30 seconds (ensures app is backgrounded but still in memory)
3. Press Record
4. Tap sacdia-app icon
5. Stop after first frame renders
```

#### What to Look For in the Trace

In the Time Profiler track, filter by **Thread: Main Thread**. Look for:

- Long `UIApplicationMain` initialization block (should be < 100 ms)
- `GeneratedPluginRegistrant.register` — this registers all Flutter plugins synchronously. Each plugin adds time.
- `GMSServices.provideAPIKey` in `AppDelegate.swift` — Google Maps SDK initialization. Expected: 20–60 ms.
- `Firebase.configure` — Firebase SDK. Expected: 30–100 ms.
- Heavy Dart code before `runApp()` — check if `_checkAndCleanSessionAtStartup` is running synchronously (it uses `addPostFrameCallback`, so it should not block first frame)

#### Acceptable Thresholds

```
Cold launch total:  < 350 ms (P50 target)
Warm launch total:  < 150 ms (P50 target)
Plugin registration: < 80 ms total
Firebase init:      < 100 ms
GMS init:           < 60 ms
```

#### Flutter-Specific: Dart VM Startup

The Dart VM itself has startup cost. In the trace, look for:
- `FlutterEngine.init` — should complete within 150 ms in profile mode
- `FlutterDartProject.init` — Dart isolate creation
- `FlutterViewController.loadView` — triggers the first rasterize

The Hermes equivalent for Flutter is the Dart AOT snapshot. In `--profile` mode you get AOT, so cold start is realistic. In `--debug`, the JIT startup is 3–5x slower and should never be used for launch benchmarks.

---

### 2.2 Hang Detection — Thread State Trace

**Goal**: Find main thread blocking operations > 250 ms.

#### Setup

1. Template: **Thread State Trace** (under All Templates > System)
2. Alternative: **Time Profiler** with System Trace enabled
3. Enable: **Hang Detection** instrument (available in Xcode 15+)

#### Procedure

```
1. Launch app in Instruments with Thread State Trace
2. Navigate through the full app flow:
   - Login screen → tap login → dashboard
   - Dashboard → members list → member detail
   - Activities → create activity → location picker (Google Maps loads)
   - Honors list → scroll fast → tap an honor
3. Each navigation step should complete < 250 ms
```

#### Reading the Hang Log

In the Thread State Trace timeline:
- **Blue**: running (main thread executing)
- **Red**: blocked (main thread waiting — this is the hang signal)
- **Orange**: preempted (OS scheduled something else)

Red segments > 16 ms cause dropped frames. Red segments > 250 ms are `MXHangDiagnostic` hangs.

Click any red segment to see the stack trace. Common Flutter offenders:

```
Hang Pattern 1: JSON decoding on main thread
Stack: DispatchQueue.main > Future.wait > jsonDecode > ...
Fix: move jsonDecode to a compute() isolate

Hang Pattern 2: SharedPreferences synchronous read
Stack: main > SharedPreferencesStorage.getString > NSUserDefaults.synchronize
Note: getString() is synchronous in the implementation at
lib/core/storage/local_storage.dart. Ensure reads happen before
runApp() or lazily, not in build().

Hang Pattern 3: Google Maps first render
Stack: GMSMapView.renderFrame > Metal renderer
Note: AppDelegate.swift already disables Metal on simulator.
On device, the first GMSMapView frame can take 200–400 ms.
Use lazy loading — only mount GoogleMap widget when the screen
is actually visible.

Hang Pattern 4: Image decoding on main thread
Stack: cached_network_image > ImageCache > dart:ui.Image.toByteData
Fix: use Image.network with cacheWidth/cacheHeight to downsample
before decoding.
```

#### How to Fix Flutter-Specific Hangs

```dart
// WRONG: JSON decoding on the calling isolate (which may be main)
final data = jsonDecode(response.data as String);

// CORRECT: offload heavy decoding
final data = await compute(jsonDecode, response.data as String);

// WRONG: synchronous SharedPreferences in a build method
final value = ref.read(storageProvider).getString('key');

// CORRECT: move to provider initialization (outside build)
// In a Riverpod FutureProvider, not inside a Widget.build
```

---

### 2.3 Memory — Allocations + Leaks

**Goal**: Identify memory leaks and excessive allocation patterns, especially with Riverpod providers, cached images, and Dio responses.

#### Setup

1. Template: **Leaks** (includes Allocations + Leak Checker)
2. For more detail: add **VM Tracker** instrument alongside

#### Procedure

```
1. Start recording
2. Navigate to dashboard — note baseline memory
3. Navigate to members list (loads network images via cached_network_image)
4. Scroll the list fast (100 items simulate a large club)
5. Navigate back to dashboard
6. CRITICAL: Check if memory returns to baseline after navigation back
   (if it doesn't, you have a leak)
7. Repeat steps 3–6 three times
8. Click "Mark Generation" before each navigation to track allocations per navigation
```

#### Identifying Flutter Leaks

Flutter leaks typically come from:

1. **StreamController not closed**: Riverpod providers that use StreamController must dispose them in `ref.onDispose`.

```dart
// In a Riverpod provider — always dispose streams
ref.onDispose(() {
  streamController.close();
  timer?.cancel();
});
```

2. **GlobalKey retained across rebuilds**: Each `GlobalKey` allocates and keeps its associated widget state alive.

3. **cached_network_image disk cache growing unbounded**: The package caches to disk in `Documents/`. Check if disk cache size is bounded.

4. **Image.network without cacheWidth**: Full-resolution images are decoded and kept in `PaintingBinding.instance.imageCache`. The default cache holds 100 images or 100 MB.

#### Memory Baseline Targets

```
App cold start (pre-login):  < 80 MB
Dashboard loaded:             < 120 MB
Members list (50 items):      < 150 MB
After navigating back:        < 130 MB (allow 10 MB flutter cache)
Peak during Google Maps:      < 180 MB
```

#### Memory Warning Handling

Flutter does not automatically handle `UIApplicationDidReceiveMemoryWarning`. Add this to your app:

```dart
// In main.dart or a root widget's initState
// Add WidgetsBindingObserver and handle memory pressure

class MyApp extends ConsumerStatefulWidget {
  // ...
}

class _MyAppState extends ConsumerState<MyApp> 
    with WidgetsBindingObserver {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didReceiveMemoryPressure() {
    // Clear image cache on memory warning
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  }
}
```

---

### 2.4 Energy — Energy Log

**Goal**: Measure CPU usage and identify location, network, and background energy drain. This is critical because Google Maps + Geolocator are the highest-risk components.

#### Setup

1. Template: **Energy Log**
2. Enable sub-instruments: CPU Activity, Network Activity, Location Activity, GPU Activity

#### Procedure

```
1. Charge device to 100 %, disconnect charger
2. Start Energy Log recording
3. Navigate through the app for 5 minutes simulating real usage:
   - 1 min: login + dashboard
   - 1 min: activities list, open an activity with a map
   - 1 min: scroll members list
   - 1 min: background the app (simulate receiving notification)
   - 1 min: re-open app
4. Stop recording
5. Note the Energy Impact score per category
```

#### Location Energy — Geolocator Risk

The highest energy risk in sacdia-app is `geolocator` + `google_maps_flutter`. In `Info.plist`, you only declare `NSLocationWhenInUseUsageDescription`, which is correct — never request `AlwaysAuthorization` unless absolutely necessary.

However, verify that geolocator is properly stopped after the location picker closes:

```dart
// WRONG: leaving a stream open
final stream = Geolocator.getPositionStream().listen((pos) { ... });
// stream.cancel() never called

// CORRECT: cancel in the widget's dispose or when map screen closes
@override
void dispose() {
  _locationSubscription?.cancel();
  super.dispose();
}
```

In Instruments Energy Log, Location Activity should show **No Location** when not on the map screen. If it shows continuous location use during dashboard or list screens, you have a leak.

#### Network Energy

In Energy Log, each Dio request shows as a Network radio wake. HTTP radio remains active for ~20 s after the last request (tail energy). Batching requests reduces this significantly.

```
Acceptable pattern: burst of requests at screen load, then radio sleeps
Problem pattern:    continuous small requests every 5-10 seconds (polling)
```

sacdia-app uses Riverpod providers that likely use `ref.watch` with `FutureProvider`. Ensure you are not re-fetching unnecessarily:

```dart
// Avoid: periodic polling via Timer in a provider
// Prefer: pull-to-refresh + cache invalidation

// If you must poll, use long intervals (> 60 s) and only while foregrounded
```

#### CPU Energy Targets

```
Foreground navigation (normal):  < 15 % CPU average
Google Maps active:               < 25 % CPU average  
Background:                       < 2 % CPU average (should be near zero)
```

---

### 2.5 Rendering — Core Animation

**Goal**: Achieve 60 FPS minimum (120 FPS on ProMotion devices like iPhone 15 Pro). Detect offscreen rendering and GPU overdraw.

#### Setup

1. Template: **Core Animation** (in Graphics category)
2. Enable: **Color Offscreen-Rendered Yellow** in Debug menu of Instruments
3. Enable: **Color Blended Layers** to see GPU overdraw

#### Procedure

```
1. Launch with Core Animation template attached to device
2. Perform the following scroll tests (each for 30 seconds):
   a. Members list — fast fling scroll
   b. Activities list — fast fling scroll
   c. Dashboard — any animated widgets (AnimatedCounter, etc.)
   d. Honors list — image-heavy list
3. Check FPS graph — must not drop below 55 FPS during any scroll
4. Check GPU Usage — should stay below 60 % during normal scroll
```

#### Reading the FPS Graph

- **Green zone (55–60 FPS)**: Acceptable
- **Yellow zone (40–55 FPS)**: Jank — one dropped frame per second
- **Red zone (< 40 FPS)**: Severe jank — multiple dropped frames

Click any FPS drop to see the corresponding rendering call tree. Look for:

```
Problem: saveLayer() calls
  - Each saveLayer() forces an offscreen render pass
  - Flutter widgets that cause implicit saveLayer: 
    ShaderMask, ColorFilter, Opacity (when animated), 
    BackdropFilter, ClipRRect with shadows

Problem: Large image decode during scroll  
  - cached_network_image decodes on scroll
  - Fix: set memCacheWidth/memCacheHeight to display size

Problem: RepaintBoundary missing on scroll children
  - Each child repaints when the list scrolls
  - Fix: wrap complex list items in RepaintBoundary
```

#### Flutter-Specific: ProMotion (120 FPS) on iPhone 15 Pro

sacdia-app's `Info.plist` already contains `CADisableMinimumFrameDurationOnPhone = true`, which correctly enables 120 FPS on ProMotion devices. Verify the rendering actually reaches 120 FPS:

In Core Animation instrument, the FPS graph should show values up to 120 on ProMotion hardware. If it stays at 60, check:

1. Confirm `CADisableMinimumFrameDurationOnPhone` is `true` in Info.plist (it is — confirmed in Runner/Info.plist line 13)
2. Confirm no `CADisplayLink` with explicit `preferredFramesPerSecond = 60` in native code

#### Offscreen Rendering — What to Fix

```dart
// CAUSES offscreen render (yellow in Instruments):
ClipRRect(
  borderRadius: BorderRadius.circular(8),
  child: Container(color: Colors.red),
)

// PREFERRED — use decoration instead:
Container(
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(8),
    color: Colors.red,
  ),
)

// CAUSES saveLayer (especially expensive during animation):
Opacity(
  opacity: _animation.value, // animated opacity
  child: ExpensiveWidget(),
)

// PREFERRED — fade without saveLayer:
FadeTransition(
  opacity: _animation,
  child: ExpensiveWidget(),
)
```

---

### 2.6 Disk I/O — File Activity

**Goal**: Identify excessive disk writes from SharedPreferences, cached_network_image disk cache, and any file operations.

#### Setup

1. Template: **File Activity** (under I/O category)
2. Enable sub-instruments: Reads, Writes, File Attributes

#### Procedure

```
1. Start File Activity recording
2. Navigate the app for 2 minutes:
   - Login (writes auth token to SharedPreferences)
   - Load 3 screens with network images
   - Logout
3. Filter results by process: sacdia_app
4. Sort by Write Bytes descending
```

#### What to Look for

```
Expected writes:
- SharedPreferences .plist writes (< 10 KB each, should only write on data change)
- cached_network_image disk cache (images saved to Library/Caches/)
- Firebase token storage

Problem writes:
- Frequent .plist rewrites on every navigation (means your providers 
  are saving on every state change instead of only on significant changes)
- Large writes to Documents/ (inappropriate for cache data — use Caches/)
- Duplicate image saves (if images are saved both by cached_network_image 
  and manually)
```

#### SharedPreferences Write Pattern

sacdia-app uses `SharedPreferencesStorage` for general data and `FlutterSecureStorage` for tokens. SharedPreferences writes synchronously to `NSUserDefaults`, which flushes to disk. Verify it is not called in a `Riverpod` provider's `build()` method.

```dart
// WRONG: saves on every provider build (can be dozens of times per second)
@override
Widget build(BuildContext context, WidgetRef ref) {
  final data = ref.watch(someProvider);
  storage.saveString('cache', data.toString()); // writes on every rebuild
  return ...;
}

// CORRECT: save only on explicit user action or significant state change
void onSave() async {
  await storage.saveString('cache', data.toString());
}
```

#### Disk Write Target

```
Total writes per navigation session (5 min):  < 5 MB
SharedPreferences per hour:                   < 50 writes
Image cache disk size:                         < 50 MB (bounded by cached_network_image config)
```

To bound the image cache:

```dart
// In main() before runApp():
PaintingBinding.instance.imageCache.maximumSizeBytes = 50 * 1024 * 1024; // 50 MB memory
// For cached_network_image disk cache, set maxNrOfCacheObjects in CacheManager config
```

---

## Part 3: Flutter DevTools Profiling

### Setup

```bash
# Run app in profile mode on device
cd /Users/abner/Documents/development/sacdia/sacdia-app
flutter run --profile

# DevTools launches automatically, or open manually:
flutter pub global activate devtools
flutter pub global run devtools
# Then connect to the running app URL shown in terminal
```

### 3.1 Performance Overlay

Enable directly in the app for quick in-hand profiling:

```dart
// Temporarily in MyApp.build() during profiling only
MaterialApp.router(
  showPerformanceOverlay: true, // REMOVE before release
  ...
)
```

The overlay shows two graphs:
- **Top graph (GPU thread / Raster thread)**: time to rasterize each frame. Must stay below the 16 ms line (60 FPS) or 8 ms line (120 FPS).
- **Bottom graph (UI thread)**: time to build the widget tree. Must stay below 16 ms.

When both graphs are green (below the line), you have smooth rendering. Red bars indicate a dropped frame.

**sacdia-app specific**: During `LocationPickerView` and `ActivityHeroSection` (the screens with `GoogleMap` widget), expect the raster thread to spike on first map load. This is normal. The spike should not persist — it should stabilize within 500 ms.

### 3.2 CPU Profiler — Flame Chart

In DevTools > Performance tab:

```
1. Start recording
2. Perform the action to profile (e.g., loading the members list)
3. Stop recording
4. Inspect the flame chart
```

Reading the flame chart:
- Width of a block = CPU time spent
- Depth = call stack depth
- Color: Dart (blue), native (orange), platform (yellow)

Look for wide blocks in Dart code during idle moments (should be no wide Dart blocks when the UI is not changing).

Common sacdia-app bottlenecks to look for:

```
Pattern: Wide block during list scroll → Provider rebuilding too many widgets
Fix: Use select() to subscribe to only the needed part of state

Pattern: Wide block on Dio response → JSON parsing on main isolate  
Fix: Use compute() for large responses (e.g., members list with 100+ items)

Pattern: Wide block during navigation → GoRouter rebuilding widget tree
Fix: Use const constructors and RepaintBoundary on static sections
```

### 3.3 Memory Profiler — Snapshot Diffing

In DevTools > Memory tab:

```
1. Navigate to the screen you want to test
2. Click "Take Snapshot" — this is the baseline
3. Perform the action that might leak (e.g., navigate to member detail and back)
4. Click "Take Snapshot" again
5. Compare: classes with increased instance count may be leaking
```

Focus on these classes for sacdia-app:
- `DioCancelToken` — should not accumulate (cancel tokens not properly cleaned up)
- `StreamSubscription` — check for unbounded growth
- `Uint8List` — large image byte arrays that should have been GC'd

### 3.4 Widget Inspector — Rebuild Detection

In DevTools > Widget Inspector:

```
1. Enable "Track widget rebuilds" toggle (top right)
2. Navigate the app
3. Widgets with high rebuild counts highlight in the inspector
```

Performance killer: a widget rebuilding 60+ times per second when it does not visually change. Common causes in Riverpod apps:

```dart
// PROBLEM: watching a provider that changes frequently
final count = ref.watch(counterProvider); // rebuilds every 16ms if counter animates

// PROBLEM: no const constructor prevents identical rebuilds
class MemberTile extends StatelessWidget {
  MemberTile({required this.member}); // missing const

// FIX: add const and ensure == works on model (use Equatable or freezed)
const MemberTile({super.key, required this.member});
```

### 3.5 Network Profiler — Request Waterfall

In DevTools > Network tab (requires running app in debug or profile mode with network profiling enabled):

```dart
// Enable in DioClient (development only, already has LoggerInterceptor):
// The LoggerInterceptor at lib/core/network/interceptors/ already logs requests.
// DevTools Network tab captures them automatically when running via flutter run.
```

Look for:
- Requests happening in parallel vs. sequential (parallel is better)
- Large response payloads (> 100 KB) that should be paginated
- Repeated requests for the same resource (missing cache)
- Requests fired during fast navigation that are abandoned (need cancellation)

**Dio request cancellation** — currently the RetryInterceptor at `lib/core/network/dio_client.dart` retries on connection errors. Verify that if a user navigates away before a request completes, it is cancelled:

```dart
// In a Riverpod provider, cancel Dio requests on dispose:
final cancelToken = CancelToken();
ref.onDispose(() => cancelToken.cancel());

final response = await dioClient.get('/endpoint', cancelToken: cancelToken);
```

---

## Part 4: Automated Performance Testing

### 4.1 Integration Test Performance Benchmarks

Flutter's `integration_test` package supports performance timeline capture.

Create the test file at `/Users/abner/Documents/development/sacdia/sacdia-app/integration_test/perf_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sacdia_app/main.dart' as app;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Performance benchmarks', () {
    testWidgets('Dashboard scroll performance', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Measure scroll performance
      await binding.watchPerformance(() async {
        final listFinder = find.byType(ListView).first;
        await tester.fling(listFinder, const Offset(0, -500), 5000);
        await tester.pumpAndSettle();
      }, reportKey: 'dashboard_scroll');
    });

    testWidgets('Login to dashboard cold path', (tester) async {
      final stopwatch = Stopwatch()..start();
      
      app.main();
      await tester.pumpAndSettle();
      
      stopwatch.stop();
      final launchMs = stopwatch.elapsedMilliseconds;
      
      // Assert cold launch < 2000 ms (conservative for CI)
      expect(launchMs, lessThan(2000),
          reason: 'Cold launch took ${launchMs}ms, expected < 2000ms');
    });
  });
}
```

Run benchmarks:

```bash
# On connected device
flutter test integration_test/perf_test.dart --device-id <device-id>

# Save timeline to file
flutter test integration_test/perf_test.dart \
  --device-id <device-id> \
  --reporter json > perf_results.json
```

### 4.2 Benchmark Script for Key Flows

Create `/Users/abner/Documents/development/sacdia/sacdia-app/integration_test/scroll_benchmark_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Scroll smoothness — members list', (tester) async {
    // Navigate to members list first
    // ...

    final result = await binding.watchPerformance(() async {
      for (int i = 0; i < 5; i++) {
        await tester.fling(
          find.byType(CustomScrollView).first,
          const Offset(0, -300),
          2000,
        );
        await tester.pumpAndSettle();
      }
    }, reportKey: 'members_scroll');

    // Parse result
    final summary = result.summary;
    final missedFrames = summary['missed_frame_build_budget_count'] as int? ?? 0;
    final totalFrames = summary['frame_count'] as int? ?? 1;
    final jankRate = missedFrames / totalFrames;

    expect(jankRate, lessThan(0.05),
        reason: 'Jank rate $jankRate exceeds 5% threshold');
  });
}
```

### 4.3 CI Metrics to Track

In your CI pipeline (GitHub Actions, Codemagic, or Bitrise), track these metrics on every PR:

```yaml
# Example GitHub Actions step for Flutter performance
- name: Run performance benchmarks
  run: |
    flutter test integration_test/ \
      --device-id "${{ env.DEVICE_ID }}" \
      --reporter json \
      | tee perf_report.json

- name: Check frame budget violations
  run: |
    # Extract missed_frame_build_budget_count from JSON
    MISSED=$(cat perf_report.json | python3 -c "
    import json, sys
    data = json.load(sys.stdin)
    print(data.get('missed_frame_build_budget_count', 0))
    ")
    echo "Missed frames: $MISSED"
    if [ "$MISSED" -gt 10 ]; then
      echo "FAIL: Too many dropped frames ($MISSED)"
      exit 1
    fi
```

### 4.4 MetricKit Integration for Production Monitoring

MetricKit runs on real user devices and reports to Xcode Organizer. Flutter does not expose MetricKit directly, but you can receive the reports via a native Swift extension.

Create `/Users/abner/Documents/development/sacdia/sacdia-app/ios/Runner/PerformanceMonitor.swift`:

```swift
import MetricKit
import Firebase

/// Receives MetricKit payloads and forwards key metrics to Firebase Analytics
/// for production monitoring alongside Xcode Organizer data.
@available(iOS 13.0, *)
class PerformanceMonitor: NSObject, MXMetricManagerSubscriber {

  static let shared = PerformanceMonitor()

  func startMonitoring() {
    MXMetricManager.shared.add(self)
  }

  func stopMonitoring() {
    MXMetricManager.shared.remove(self)
  }

  // Called once per day with aggregated metrics
  func didReceive(_ payloads: [MXMetricPayload]) {
    for payload in payloads {
      reportLaunchMetrics(payload)
      reportHangMetrics(payload)
      reportMemoryMetrics(payload)
    }
  }

  // Called immediately when a hang or crash diagnostic is available
  func didReceive(_ payloads: [MXDiagnosticPayload]) {
    for payload in payloads {
      if let hangDiagnostics = payload.hangDiagnostics {
        for hang in hangDiagnostics {
          let duration = hang.hangDuration.converted(to: .milliseconds).value
          // Log to Firebase Analytics or Crashlytics
          // Analytics.logEvent("hang_detected", parameters: ["duration_ms": duration])
          print("[PerformanceMonitor] Hang detected: \(duration) ms")
        }
      }
    }
  }

  private func reportLaunchMetrics(_ payload: MXMetricPayload) {
    guard let launchMetrics = payload.applicationLaunchMetrics else { return }
    let histogram = launchMetrics.histogrammedTimeToFirstDraw
    // Log P50 and P90 to your analytics
    print("[PerformanceMonitor] Launch histogram: \(histogram)")
  }

  private func reportHangMetrics(_ payload: MXMetricPayload) {
    guard let animationMetrics = payload.applicationResponsivenessMetrics else { return }
    let hangRate = animationMetrics.histogrammedAppHangTime
    print("[PerformanceMonitor] Hang rate: \(hangRate)")
  }

  private func reportMemoryMetrics(_ payload: MXMetricPayload) {
    guard let memMetrics = payload.memoryMetrics else { return }
    let peak = memMetrics.peakMemoryUsage.converted(to: .megabytes).value
    print("[PerformanceMonitor] Peak memory: \(peak) MB")
  }
}
```

Register it in `AppDelegate.swift`:

```swift
// Add to AppDelegate.swift, inside application(_:didFinishLaunchingWithOptions:)
if #available(iOS 13.0, *) {
  PerformanceMonitor.shared.startMonitoring()
}
```

This gives you production hang and launch data per app version, visible in Xcode Organizer within 24 hours of user device reports.

---

## Part 5: Pre-Submission Checklist

Run this checklist on a physical device (not simulator) before every App Store submission. Use iPhone 14 or older (more representative of P90 users than iPhone 15 Pro).

### 5.1 Launch Performance

- [ ] Cold launch < 400 ms (measured in Xcode Instruments App Launch template, P50)
- [ ] Cold launch < 2000 ms (P90 — no user sees > 2 s)
- [ ] Warm launch < 200 ms
- [ ] No main thread work before first frame except: orientation, SharedPreferences, Firebase init
- [ ] `_checkAndCleanSessionAtStartup` runs via `addPostFrameCallback` (does not block first frame) — confirmed in `main.dart:49`
- [ ] Firebase init completes < 100 ms (check with App Launch instrument)
- [ ] GMSServices init completes < 60 ms

### 5.2 Responsiveness / Hang Rate

- [ ] Zero hangs > 250 ms during normal navigation
- [ ] Zero hangs > 250 ms during list scrolling (members, activities, honors)
- [ ] JSON decoding for responses > 50 KB uses `compute()`
- [ ] No synchronous file reads in `build()` methods
- [ ] Google Maps location stream is cancelled when LocationPickerView is disposed
- [ ] All Dio `CancelToken` instances are cancelled in `ref.onDispose()`

### 5.3 Memory

- [ ] Baseline memory (post-login dashboard) < 120 MB
- [ ] Members list with 50 items loaded < 150 MB
- [ ] Memory returns to within 10 MB of baseline after navigating away from lists
- [ ] No growing `DioCancelToken` or `StreamSubscription` instance counts (DevTools Memory snapshot diff)
- [ ] `didReceiveMemoryPressure()` calls `PaintingBinding.instance.imageCache.clear()`
- [ ] Image memory cache bounded at 50 MB (set in `main()`)
- [ ] `cached_network_image` disk cache bounded at 50 MB

### 5.4 Rendering

- [ ] Sustained 60 FPS on iPhone 14 during all list scrolls
- [ ] 120 FPS on ProMotion device (iPhone 15 Pro) — `CADisableMinimumFrameDurationOnPhone = true` confirmed in Info.plist
- [ ] No Core Animation offscreen renders on list items (check with Instruments Color Offscreen Rendered)
- [ ] No `Opacity` widget on animating children (use `FadeTransition` instead)
- [ ] No `ClipRRect` + `BoxShadow` combination on list tiles (use `BoxDecoration` only)
- [ ] `RepaintBoundary` wraps complex list items with static content
- [ ] Flutter Performance Overlay shows green bars during scroll (test locally, remove before release)

### 5.5 Energy / Battery

- [ ] Location stream from `geolocator` not active outside of map screens
- [ ] No background location usage (`NSLocationAlwaysUsageDescription` not in Info.plist) — confirmed: only `NSLocationWhenInUseUsageDescription` declared
- [ ] No polling timers with interval < 60 s while app is active
- [ ] Dio requests are batched at screen load, not one by one
- [ ] `firebase_messaging` background handler does minimal work (no heavy computation in `onBackgroundMessage`)
- [ ] CPU in background < 2 % (verify with Energy Log instrument while app is backgrounded)

### 5.6 Disk I/O

- [ ] SharedPreferences not written in `build()` methods
- [ ] Image cache does not write to `Documents/` (must go to `Library/Caches/` — `cached_network_image` does this correctly by default)
- [ ] No debug log files written to disk in release builds (`AppLogger` only logs when `kDebugMode` is true)
- [ ] Total disk writes < 5 MB for a 5-minute user session

### 5.7 Network

- [ ] All requests use HTTPS (enforced: `NSAllowsArbitraryLoads = false` in Info.plist)
- [ ] `RetryInterceptor` only retries idempotent methods (GET, HEAD, DELETE, PUT) — confirmed in `dio_client.dart:112`
- [ ] Large list responses (> 50 items) are paginated
- [ ] Requests for the same resource are not duplicated when multiple widgets mount simultaneously (use `ref.watch` with a shared provider, not individual fetches)
- [ ] Authentication token refresh does not cause duplicate requests (verify `AuthInterceptor` queues concurrent 401 retries)

### 5.8 App Store Technical Requirements

- [ ] Binary size < 40 MB (download size, after App Store compression)
- [ ] No private API usage (verify with `nm` tool on the binary)
- [ ] Privacy manifest `PrivacyInfo.xcprivacy` updated with all accessed API categories — currently declares UserDefaults, FileTimestamp, DiskSpace
- [ ] All third-party SDKs include their own privacy manifests (Firebase, Google Maps — verify via Pods)
- [ ] App does not crash in the first 3 taps from a fresh install
- [ ] App functions when all optional permissions are denied (location denied = maps screen shows error, not crash)

### 5.9 Quick Verification Commands

```bash
# Build in release mode and check binary size
cd /Users/abner/Documents/development/sacdia/sacdia-app
flutter build ios --release
# Check .ipa size after archiving in Xcode

# Run analyzer to catch obvious issues
flutter analyze

# Run all tests
flutter test

# Check for debug artifacts in release build
flutter build ios --release --verbose 2>&1 | grep -i "debug\|assert"

# Profile mode build for Instruments profiling
flutter build ios --profile --no-codesign

# Open Instruments
open -a Instruments
```

---

## Appendix A: Instruments Quick Reference

| What you're investigating | Template | Key track |
|--------------------------|----------|-----------|
| Slow launch | App Launch | Launch timeline |
| UI hangs | Thread State Trace | Main thread blocks |
| Memory leak | Leaks | Generations view |
| Battery drain | Energy Log | CPU / Location / Network activity |
| Dropped frames | Core Animation | FPS graph |
| Disk writes | File Activity | Write bytes by file |
| Metal GPU usage | Game Performance | GPU counters |

## Appendix B: Flutter DevTools Quick Reference

| What you're investigating | DevTools tab | Key feature |
|--------------------------|--------------|-------------|
| Frame drops | Performance | Flutter frames chart |
| CPU bottleneck | Performance > CPU Profiler | Flame chart |
| Memory leak | Memory | Snapshot diff |
| Widget rebuilds | Widget Inspector | Rebuild count |
| Network waterfall | Network | Request timeline |
| Provider state | Provider Inspector | State tree |

## Appendix C: Threshold Summary Card

Print this and keep it next to your monitor.

```
SACDIA-APP PERFORMANCE BUDGET — iOS

LAUNCH
  Cold:        < 350 ms P50   | < 2000 ms P90
  Warm:        < 150 ms P50

RESPONSIVENESS
  Hangs:       0 per session > 250 ms
  Frame build: < 16 ms (60 FPS) | < 8 ms (120 FPS ProMotion)

MEMORY
  Baseline:    < 120 MB
  Peak:        < 180 MB
  After nav:   returns to baseline ± 10 MB

ENERGY
  CPU fore:    < 15 % avg
  CPU back:    < 2 % avg
  Location:    ONLY on map screens

DISK
  Writes/session: < 5 MB per 5 min
  Image cache:    < 50 MB disk

NETWORK
  All HTTPS    ✓ (enforced in Info.plist)
  Retries:     idempotent only ✓ (verified in DioClient)
  Pagination:  required for > 50 item lists
```
