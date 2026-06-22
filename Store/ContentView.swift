//
//  ContentView.swift
//  Store
//
//  Public API surface for the Store library. A premium dark-themed picker
//  that presents one mini app at a time as a full-screen "world." Parent
//  apps construct ``MiniApp`` values and pass them to ``ContentView``.
//

#if os(iOS)

import SwiftUI

// MARK: - MiniApp

/// A single mini app to be presented inside a ``ContentView``.
///
/// Each ``MiniApp`` is a self-contained value carrying its presentation
/// metadata (name, tagline, icon, tint) and a lazily-constructed
/// destination view shown when the user opens it. Equality and hashing
/// are based on ``id`` only so that the value can drive
/// `NavigationLink(value:)` and `scrollPosition(id:)` without including
/// the destination closure in identity.
///
/// ```swift
/// MiniApp(
///     id: "lyrics",
///     name: "Lyrics Editor",
///     tagline: "Write and refine songs",
///     systemImage: "music.note.list",
///     tint: .purple
/// ) {
///     LyricsEditorScreen()
/// }
/// ```
public struct MiniApp: Identifiable, Hashable {
    /// A stable identifier unique within a ``ContentView``'s app list.
    public let id: String

    /// The localized display name of the app.
    public let name: LocalizedStringResource

    /// A short localized description shown beneath the name.
    public let tagline: LocalizedStringResource

    /// The icon presentation — an SF Symbol or an asset catalog image.
    public let icon: Icon

    /// The accent color used for the icon background and ambient effects.
    public let tint: Color

    let destination: () -> AnyView

    /// Describes how a ``MiniApp``'s icon is rendered.
    public enum Icon: Hashable, Sendable {
        /// Render an SF Symbol with the given name.
        case systemImage(String)
        /// Render an asset catalog image resource.
        case asset(ImageResource)
    }

    /// Creates a mini app with an explicit ``Icon``.
    public init<Destination: View>(
        id: String,
        name: LocalizedStringResource,
        tagline: LocalizedStringResource,
        icon: Icon,
        tint: Color,
        @ViewBuilder destination: @escaping () -> Destination
    ) {
        self.id = id
        self.name = name
        self.tagline = tagline
        self.icon = icon
        self.tint = tint
        self.destination = { AnyView(destination()) }
    }

    /// Creates a mini app using an SF Symbol as the icon.
    public init<Destination: View>(
        id: String,
        name: LocalizedStringResource,
        tagline: LocalizedStringResource,
        systemImage: String,
        tint: Color,
        @ViewBuilder destination: @escaping () -> Destination
    ) {
        self.init(
            id: id,
            name: name,
            tagline: tagline,
            icon: .systemImage(systemImage),
            tint: tint,
            destination: destination
        )
    }

    public static func == (lhs: MiniApp, rhs: MiniApp) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Appearance

/// The dark surface palette used by ``ContentView`` and its subviews.
///
/// Override per-instance with the ``SwiftUICore/View/storeAppearance(_:)``
/// modifier on any ``ContentView`` or ancestor view:
///
/// ```swift
/// ContentView(miniApps: apps)
///     .storeAppearance(.init(canvas: .black))
/// ```
public struct StoreAppearance: Sendable {
    /// The full-bleed background color of every world.
    public var canvas: Color
    /// A subtle fill used for cards, capsules, and search field.
    public var surface: Color
    /// A slightly stronger surface fill used for selected rows.
    public var surfaceStrong: Color
    /// A 1-px border color used on interactive elements.
    public var hairline: Color
    /// A softer 1-px border color used on container edges.
    public var hairlineSoft: Color
    /// The mid-weight foreground color used for taglines.
    public var muted: Color
    /// The lightest foreground color used for metadata.
    public var mutedSoft: Color

    public init(
        canvas: Color = Color(red: 0.04, green: 0.04, blue: 0.05),
        surface: Color = Color.white.opacity(0.04),
        surfaceStrong: Color = Color.white.opacity(0.06),
        hairline: Color = Color.white.opacity(0.10),
        hairlineSoft: Color = Color.white.opacity(0.06),
        muted: Color = Color.white.opacity(0.50),
        mutedSoft: Color = Color.white.opacity(0.35)
    ) {
        self.canvas = canvas
        self.surface = surface
        self.surfaceStrong = surfaceStrong
        self.hairline = hairline
        self.hairlineSoft = hairlineSoft
        self.muted = muted
        self.mutedSoft = mutedSoft
    }
}

private struct StoreAppearanceKey: EnvironmentKey {
    static let defaultValue = StoreAppearance()
}

public extension EnvironmentValues {
    /// The dark surface palette used by ``ContentView`` and its subviews.
    var storeAppearance: StoreAppearance {
        get { self[StoreAppearanceKey.self] }
        set { self[StoreAppearanceKey.self] = newValue }
    }
}

public extension View {
    /// Overrides the dark surface palette used by ``ContentView``.
    func storeAppearance(_ appearance: StoreAppearance) -> some View {
        environment(\.storeAppearance, appearance)
    }
}

// MARK: - ContentView

/// A premium dark-themed picker screen that presents mini apps as
/// immersive full-screen "worlds."
///
/// On compact size classes (iPhone) each app fills the screen as its own
/// page; users swipe horizontally between worlds or long-press to open a
/// grid overview. On regular size classes (iPad) a sidebar lists every
/// app with search, and the detail column shows the selected world.
///
/// The view is "pure" — the parent app supplies the list of ``MiniApp``
/// values and their destination views. Navigation is driven by an
/// internal `NavigationStack` value-based destination using a matched
/// geometry zoom transition from the icon into the destination.
///
/// ```swift
/// NavigationStack {
///     ContentView(miniApps: parentApps)
/// }
/// ```
public struct ContentView: View {

    /// The title shown above the iPad sidebar and used by VoiceOver.
    public let title: LocalizedStringResource

    /// The apps to present. When empty, the view shows a graceful
    /// empty state.
    public let miniApps: [MiniApp]

    let emptyStateBuilder: (() -> AnyView)?

    @State private var selection: String?
    @State private var searchText: String = ""
    @State private var showingOverview: Bool = false
    @Namespace private var zoomNamespace
    @Environment(\.storeAppearance) private var appearance
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.horizontalSizeClass) private var sizeClass

    /// Creates a Mini App Store screen with the built-in empty state.
    ///
    /// - Parameters:
    ///   - title: A localized title shown above the iPad sidebar.
    ///     Defaults to "Mini Apps".
    ///   - miniApps: The apps to present. If empty, the view shows a
    ///     graceful empty state.
    public init(
        title: LocalizedStringResource = "Mini Apps",
        miniApps: [MiniApp]
    ) {
        self.title = title
        self.miniApps = miniApps
        self.emptyStateBuilder = nil
        _selection = State(initialValue: miniApps.first?.id)
    }

    /// Creates a Mini App Store screen with a custom empty state view.
    ///
    /// Use this overload when you want full control over the UI shown
    /// when the app list is empty — for example, to display a CTA
    /// button or branded illustration.
    ///
    /// - Parameters:
    ///   - title: A localized title shown above the iPad sidebar.
    ///   - miniApps: The apps to present.
    ///   - emptyState: A view builder that produces the empty state.
    ///     Only used when `miniApps` is empty.
    public init<EmptyContent: View>(
        title: LocalizedStringResource = "Mini Apps",
        miniApps: [MiniApp],
        @ViewBuilder emptyState: @escaping () -> EmptyContent
    ) {
        self.title = title
        self.miniApps = miniApps
        self.emptyStateBuilder = { AnyView(emptyState()) }
        _selection = State(initialValue: miniApps.first?.id)
    }

    private var filteredApps: [MiniApp] {
        guard !searchText.isEmpty else { return miniApps }
        return miniApps.filter {
            String(localized: $0.name).localizedStandardContains(searchText) ||
                String(localized: $0.tagline).localizedStandardContains(searchText)
        }
    }

    public var body: some View {
        ZStack {
            Group {
                if miniApps.isEmpty {
                    emptyState
                } else if sizeClass == .regular {
                    regularLayout
                } else {
                    compactLayout
                }
            }

            if showingOverview && !miniApps.isEmpty {
                AppGridOverview(
                    title: title,
                    apps: miniApps,
                    selection: $selection,
                    isPresented: $showingOverview
                )
                .transition(.opacity)
            }
        }
        .background(appearance.canvas.ignoresSafeArea())
        .sensoryFeedback(.selection, trigger: selection)
        .sensoryFeedback(.impact(weight: .medium), trigger: showingOverview) { _, new in new }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationDestination(for: MiniApp.self) { app in
            app.destination()
                .navigationTransition(.zoom(sourceID: app.id, in: zoomNamespace))
        }
        .preferredColorScheme(.dark)
    }

    // MARK: Empty state

    @ViewBuilder
    private var emptyState: some View {
        if let emptyStateBuilder {
            emptyStateBuilder()
        } else {
            defaultEmptyState
        }
    }

    private var defaultEmptyState: some View {
        ContentUnavailableView {
            Label {
                Text("No Mini Apps")
            } icon: {
                Image(systemName: "square.dashed")
            }
        } description: {
            Text("Add mini apps to get started.")
        }
        .foregroundStyle(.white)
    }

    // MARK: Compact

    private var compactLayout: some View {
        worldsScroller
    }

    private var worldsScroller: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 0) {
                ForEach(miniApps) { app in
                    MiniAppWorld(
                        app: app,
                        isActive: selection == app.id,
                        namespace: zoomNamespace,
                        reduceMotion: reduceMotion,
                        onLongPress: openOverview
                    )
                    .containerRelativeFrame(.horizontal)
                    .id(app.id)
                    .scrollTransition(axis: .horizontal) { [reduceMotion] content, phase in
                        content
                            .opacity(reduceMotion ? 1 : (phase.isIdentity ? 1 : 0.4))
                    }
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: $selection)
        .scrollIndicators(.hidden)
    }

    private func openOverview() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            showingOverview = true
        }
    }

    // MARK: Regular

    private var regularLayout: some View {
        HStack(spacing: 0) {
            sidebar
                .frame(width: 300)

            Rectangle()
                .fill(appearance.hairlineSoft)
                .frame(width: 0.5)
                .ignoresSafeArea()

            ZStack {
                if let app = miniApps.first(where: { $0.id == selection }) {
                    MiniAppWorld(
                        app: app,
                        isActive: true,
                        namespace: zoomNamespace,
                        reduceMotion: reduceMotion,
                        onLongPress: openOverview
                    )
                    .id(app.id)
                    .transition(.opacity)
                }
            }
            .animation(.easeOut(duration: 0.25), value: selection)
        }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .tracking(-0.4)
                .padding(.horizontal, 16)
                .padding(.top, 28)

            Text("^[\(miniApps.count) app](inflect: true)")
                .font(.footnote)
                .foregroundStyle(appearance.mutedSoft)
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 16)

            searchField
                .padding(.horizontal, 12)
                .padding(.bottom, 12)

            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(filteredApps) { app in
                        Button {
                            withAnimation(.easeOut(duration: 0.18)) {
                                selection = app.id
                            }
                        } label: {
                            SidebarRow(app: app, isSelected: selection == app.id)
                        }
                        .buttonStyle(.plain)
                    }

                    if filteredApps.isEmpty {
                        Text("No results")
                            .font(.footnote)
                            .foregroundStyle(appearance.mutedSoft)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 24)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 20)
            }
        }
        .background(appearance.canvas)
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(appearance.mutedSoft)
            TextField("Search", text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .foregroundStyle(.white)
                .submitLabel(.search)
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(appearance.mutedSoft)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("Clear search"))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(appearance.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(appearance.hairlineSoft, lineWidth: 0.5)
        )
    }
}

// MARK: - Icon view (internal)

private struct MiniAppIconImage: View {
    let icon: MiniApp.Icon
    let pointSize: CGFloat
    let bounceTrigger: Bool

    var body: some View {
        switch icon {
        case .systemImage(let name):
            Image(systemName: name)
                .font(.system(size: pointSize, weight: .medium))
                .foregroundStyle(.white)
                .symbolEffect(.bounce, options: .nonRepeating, value: bounceTrigger)
        case .asset(let resource):
            Image(resource)
                .resizable()
                .scaledToFit()
                .padding(pointSize * 0.16)
                .foregroundStyle(.white)
        }
    }
}

// MARK: - Sidebar row (internal)

private struct SidebarRow: View {
    let app: MiniApp
    let isSelected: Bool

    @Environment(\.storeAppearance) private var appearance

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(app.tint)
                MiniAppIconImage(icon: app.icon, pointSize: 14, bounceTrigger: false)
            }
            .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 1) {
                Text(app.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
                Text(app.tagline)
                    .font(.caption)
                    .foregroundStyle(appearance.mutedSoft)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isSelected ? appearance.surfaceStrong : Color.clear)
        )
        .contentShape(Rectangle())
        .hoverEffect()
    }
}

// MARK: - World (internal)

private struct MiniAppWorld: View {
    let app: MiniApp
    let isActive: Bool
    let namespace: Namespace.ID
    let reduceMotion: Bool
    let onLongPress: () -> Void

    @Environment(\.storeAppearance) private var appearance

    var body: some View {
        ZStack {
            appearance.canvas.ignoresSafeArea()
            vignette

            VStack(spacing: 0) {
                Spacer(minLength: 40)

                iconBadge
                    .matchedTransitionSource(id: app.id, in: namespace)
                    .scaleEffect(reduceMotion ? 1.0 : (isActive ? 1.0 : 0.96))
                    .animation(.spring(response: 0.5, dampingFraction: 0.78), value: isActive)
                    .scrollTransition(axis: .horizontal) { content, phase in
                        content
                            .offset(x: reduceMotion ? 0 : -phase.value * 36)
                    }
                    .padding(.bottom, 44)

                Text(app.name)
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(.white)
                    .tracking(-0.5)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 10)
                    .dynamicTypeSize(...DynamicTypeSize.accessibility1)

                Text(app.tagline)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(appearance.muted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 44)
                    .dynamicTypeSize(...DynamicTypeSize.accessibility2)

                Spacer(minLength: 40)

                openLink
                    .padding(.bottom, 108)
            }
        }
        .contentShape(Rectangle())
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.45)
                .onEnded { _ in
                    onLongPress()
                }
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("\(Text(app.name)). \(Text(app.tagline))"))
        .accessibilityHint(Text("Double tap to open \(Text(app.name)). Touch and hold for all apps."))
        .accessibilityAddTraits(.isHeader)
        .accessibilityAction(named: Text("Show all apps")) {
            onLongPress()
        }
    }

    private var vignette: some View {
        LinearGradient(
            colors: [
                .black.opacity(0.15),
                .clear,
                .clear,
                .black.opacity(0.12)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private var iconBadge: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            app.tint,
                            app.tint.opacity(0.88)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.5)
            MiniAppIconImage(icon: app.icon, pointSize: 44, bounceTrigger: isActive)
        }
        .frame(width: 96, height: 96)
        .shadow(color: app.tint.opacity(0.30), radius: 22, y: 10)
        .accessibilityHidden(true)
    }

    private var openLink: some View {
        NavigationLink(value: app) {
            HStack(spacing: 7) {
                Text("Open")
                    .font(.system(size: 14, weight: .medium))
                Image(systemName: "arrow.right")
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 11)
            .background(
                Capsule()
                    .fill(appearance.surface)
            )
            .overlay(
                Capsule()
                    .strokeBorder(appearance.hairline, lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .hoverEffect(.lift)
        .accessibilityLabel(Text("Open \(Text(app.name))"))
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Grid overview (internal)

private struct AppGridOverview: View {
    let title: LocalizedStringResource
    let apps: [MiniApp]
    @Binding var selection: String?
    @Binding var isPresented: Bool

    @Environment(\.storeAppearance) private var appearance

    private let columns = [
        GridItem(.adaptive(minimum: 88, maximum: 120), spacing: 18)
    ]

    var body: some View {
        ZStack {
            appearance.canvas
                .opacity(0.97)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            VStack(spacing: 0) {
                HStack {
                    Text(title)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                        .tracking(-0.3)
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.80))
                            .frame(width: 30, height: 30)
                            .background(Circle().fill(appearance.surfaceStrong))
                            .overlay(Circle().strokeBorder(appearance.hairlineSoft, lineWidth: 0.5))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text("Close"))
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 22)

                ScrollView {
                    LazyVGrid(columns: columns, spacing: 22) {
                        ForEach(apps) { app in
                            Button {
                                pick(app)
                            } label: {
                                AppGridTile(app: app, isSelected: selection == app.id)
                            }
                            .buttonStyle(.plain)
                            .hoverEffect(.lift)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
    }

    private func dismiss() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            isPresented = false
        }
    }

    private func pick(_ app: MiniApp) {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            selection = app.id
            isPresented = false
        }
    }
}

private struct AppGridTile: View {
    let app: MiniApp
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [app.tint, app.tint.opacity(0.88)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.5)
                MiniAppIconImage(icon: app.icon, pointSize: 26, bounceTrigger: false)
            }
            .frame(width: 68, height: 68)
            .shadow(color: app.tint.opacity(0.30), radius: 14, y: 6)
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(
                        Color.white.opacity(isSelected ? 0.45 : 0),
                        lineWidth: 1.5
                    )
                    .padding(-4)
            )

            Text(app.name)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.85))
                .lineLimit(1)
                .multilineTextAlignment(.center)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(app.name))
        .accessibilityHint(Text("Double tap to jump to \(Text(app.name))"))
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

// MARK: - Preview

#Preview("Populated") {
    NavigationStack {
        ContentView(miniApps: [
            MiniApp(
                id: "lyricseditor",
                name: "Lyrics Editor",
                tagline: "Write, format, and refine songs",
                systemImage: "music.note.list",
                tint: Color(red: 0.62, green: 0.52, blue: 1.0)
            ) {
                Text("Lyrics Editor").foregroundStyle(.white)
            },
            MiniApp(
                id: "charactercast",
                name: "Character Cast",
                tagline: "Build casts for your stories",
                systemImage: "theatermasks.fill",
                tint: Color(red: 1.0, green: 0.55, blue: 0.42)
            ) {
                Text("Character Cast").foregroundStyle(.white)
            }
        ])
    }
}

#Preview("Empty") {
    NavigationStack {
        ContentView(miniApps: [])
    }
}

#endif
