# Store

A lightweight, pure-SwiftUI iOS library that provides a premium dark-themed picker for presenting "mini apps" as immersive, full-screen worlds. Designed for parent applications that want to expose a curated set of self-contained features without managing complex routing or navigation state.

## Features

- **Adaptive Layouts**: Horizontal swipe-based worlds on compact screens (iPhone), sidebar + detail panel on regular screens (iPad)
- **Immersive Transitions**: Matched geometry zoom animation from the app icon to the destination view
- **Search & Filtering**: Real-time filtering across app names and taglines
- **Grid Overview**: Long-press any world to reveal a dismissible app grid
- **Custom Theming**: Fully override the dark surface palette via `StoreAppearance`
- **Accessibility**: VoiceOver labels, `reduceMotion` support, dynamic type scaling, haptic feedback
- **Empty State Handling**: Built-in fallback or fully custom view builders

## Requirements

- iOS 26.0+
- Xcode 16+
- Swift 6
- No external dependencies (pure SwiftUI)

## Installation

Add the package to your project using Swift Package Manager:

**Xcode UI**: `File > Add Package Dependencies...` → Enter the repository URL.

**Package.swift**:
```swift
dependencies: [
    .package(url: "https://github.com/<your-org>/Store.git", from: "1.0.0")
]
```

Build and run the included demo by opening `Store/StoreApp.swift` in Xcode. Note that `StoreApp.swift` is excluded from the library target and only exists for demonstration purposes.

## Usage

### Basic Setup

Create `MiniApp` values and pass them to `ContentView`. Wrap the view in a `NavigationStack` to enable the built-in navigation transitions.

```swift
import SwiftUI
import Store

struct ParentView: View {
    var body: some View {
        NavigationStack {
            ContentView(miniApps: [
                MiniApp(
                    id: "lyrics",
                    name: "Lyrics Editor",
                    tagline: "Write and refine songs",
                    systemImage: "music.note.list",
                    tint: .purple
                ) {
                    LyricsEditorScreen()
                },
                MiniApp(
                    id: "metronome",
                    name: "Metronome",
                    tagline: "Tap, tempo, and time signatures",
                    systemImage: "metronome.fill",
                    tint: .red
                ) {
                    MetronomeScreen()
                }
            ])
        }
    }
}
```

### Customizing Appearance

Override the default dark palette by applying the `.storeAppearance(_:)` modifier to `ContentView` or any ancestor view.

```swift
ContentView(miniApps: apps)
    .storeAppearance(.init(
        canvas: .black,
        surface: .white.opacity(0.05),
        surfaceStrong: .white.opacity(0.08),
        hairline: .white.opacity(0.12),
        hairlineSoft: .white.opacity(0.07),
        muted: .white.opacity(0.55),
        mutedSoft: .white.opacity(0.40)
    ))
```

### Custom Empty State

Use the secondary initializer to provide a fully custom view when `miniApps` is empty.

```swift
ContentView(
    title: "My Apps",
    miniApps: [],
    emptyState: {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundStyle(.white.opacity(0.6))
            Text("No mini apps installed")
                .font(.title3)
                .foregroundStyle(.white)
            Button("Browse Store") { /* action */ }
                .buttonStyle(.borderedProminent)
        }
    }
)
```

## Architecture & Key Files

| File | Purpose |
|------|---------|
| `Package.swift` | SPM manifest. Defines the `Store` library target, iOS 26 platform constraint, and Swift 6 language mode. Excludes demo files from the library bundle. |
| `Store/ContentView.swift` | Core public API. Exports `MiniApp`, `StoreAppearance`, and `ContentView`. Contains all internal layout components (`MiniAppWorld`, `SidebarRow`, `AppGridOverview`, etc.). |
| `Store/StoreApp.swift` | Demo application entry point (`@main`). Demonstrates usage with a tabbed interface and sample mini apps. Excluded from the library target. |

## Non-Obvious Conventions & Implementation Details

- **Identity & Hashing**: `MiniApp` conforms to `Identifiable` and `Hashable` using **only the `id` property**. This prevents the destination closure from affecting equality, which is required for `NavigationLink(value:)` and `scrollPosition(id:)` to work reliably.
- **Type Erasure**: Destination views are wrapped in `AnyView` inside `MiniApp` to erase concrete types and avoid closure identity mismatches during navigation state restoration.
- **Environment-Driven Theming**: `StoreAppearance` is injected via a custom `EnvironmentKey`. It cascades down to all internal subviews (`MiniAppWorld`, `SidebarRow`, `AppGridOverview`, etc.).
- **Layout Branching**: The view automatically switches between `compactLayout` (horizontal `ScrollView` with `scrollTargetBehavior(.viewAligned)`) and `regularLayout` (sidebar + detail) based on `horizontalSizeClass`.
- **Motion & Haptics**: 
  - `sensoryFeedback(.selection)` triggers on app selection.
  - `sensoryFeedback(.impact)` triggers when toggling the grid overview.
  - `@Environment(\.accessibilityReduceMotion)` disables parallax offsets, zoom transitions, and bounce effects when enabled.
- **Navigation Destination**: The library uses `navigationDestination(for: MiniApp.self)` internally. Parent apps should **not** wrap `ContentView` in a separate `NavigationStack` unless they need to push additional screens above the mini-app worlds.
- **Search Behavior**: Filtering matches against both `name` and `tagline` using `localizedStandardContains`. The search field clears automatically when tapped, and the sidebar updates instantly.
- **Long-Press Gesture**: A `LongPressGesture(minimumDuration: 0.45)` on any world triggers the grid overview. This is also exposed to VoiceOver via `accessibilityAction(named:)`.