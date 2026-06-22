//
//  ContentView.swift
//  Store
//
//  Created by u on 21/06/2026.
//

import SwiftUI

// MARK: - Public API

struct MiniApp: Identifiable, Hashable {
    let id: String
    let name: String
    let tagline: String
    let icon: String
    let tint: Color
    let destination: () -> AnyView

    init<Destination: View>(
        id: String,
        name: String,
        tagline: String,
        icon: String,
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

    static func == (lhs: MiniApp, rhs: MiniApp) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Theme

private enum StoreTheme {
    static let canvas = Color(red: 0.04, green: 0.04, blue: 0.05)
    static let surface = Color.white.opacity(0.04)
    static let surfaceStrong = Color.white.opacity(0.06)
    static let hairline = Color.white.opacity(0.10)
    static let hairlineSoft = Color.white.opacity(0.06)
    static let muted = Color.white.opacity(0.50)
    static let mutedSoft = Color.white.opacity(0.35)
}

// MARK: - ContentView

struct ContentView: View {
    let miniApps: [MiniApp]

    @State private var selection: String?
    @State private var searchText: String = ""
    @State private var showingOverview: Bool = false
    @Namespace private var zoomNamespace
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.horizontalSizeClass) private var sizeClass

    init(miniApps: [MiniApp]) {
        self.miniApps = miniApps
        _selection = State(initialValue: miniApps.first?.id)
    }

    private var filteredApps: [MiniApp] {
        guard !searchText.isEmpty else { return miniApps }
        return miniApps.filter {
            $0.name.localizedStandardContains(searchText) ||
                $0.tagline.localizedStandardContains(searchText)
        }
    }

    var body: some View {
        ZStack {
            Group {
                if sizeClass == .regular {
                    regularLayout
                } else {
                    compactLayout
                }
            }

            if showingOverview {
                AppGridOverview(
                    apps: miniApps,
                    selection: $selection,
                    isPresented: $showingOverview
                )
                .transition(.opacity)
            }
        }
        .background(StoreTheme.canvas.ignoresSafeArea())
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
                    .scrollTransition(axis: .horizontal) { content, phase in
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
                .fill(StoreTheme.hairlineSoft)
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
            Text("Mini Apps")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .tracking(-0.4)
                .padding(.horizontal, 16)
                .padding(.top, 28)

            Text("^[\(miniApps.count) app](inflect: true)")
                .font(.footnote)
                .foregroundStyle(StoreTheme.mutedSoft)
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
                            .foregroundStyle(StoreTheme.mutedSoft)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 24)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 20)
            }
        }
        .background(StoreTheme.canvas)
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(StoreTheme.mutedSoft)
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
                        .foregroundStyle(StoreTheme.mutedSoft)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("Clear search"))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(StoreTheme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(StoreTheme.hairlineSoft, lineWidth: 0.5)
        )
    }
}

// MARK: - Sidebar row

private struct SidebarRow: View {
    let app: MiniApp
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(app.tint)
                Image(systemName: app.icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
            }
            .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 1) {
                Text(app.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
                Text(app.tagline)
                    .font(.caption)
                    .foregroundStyle(StoreTheme.mutedSoft)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isSelected ? StoreTheme.surfaceStrong : Color.clear)
        )
        .contentShape(Rectangle())
        .hoverEffect()
    }
}

// MARK: - World

private struct MiniAppWorld: View {
    let app: MiniApp
    let isActive: Bool
    let namespace: Namespace.ID
    let reduceMotion: Bool
    let onLongPress: () -> Void

    var body: some View {
        ZStack {
            StoreTheme.canvas.ignoresSafeArea()
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
                    .foregroundStyle(StoreTheme.muted)
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
        .accessibilityLabel(Text("\(app.name). \(app.tagline)"))
        .accessibilityHint(Text("Double tap to open \(app.name). Touch and hold for all apps."))
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
            Image(systemName: app.icon)
                .font(.system(size: 44, weight: .medium))
                .foregroundStyle(.white)
                .symbolEffect(.bounce, options: .nonRepeating, value: isActive)
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
                    .fill(StoreTheme.surface)
            )
            .overlay(
                Capsule()
                    .strokeBorder(StoreTheme.hairline, lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .hoverEffect(.lift)
        .accessibilityLabel(Text("Open \(app.name)"))
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Grid overview

private struct AppGridOverview: View {
    let apps: [MiniApp]
    @Binding var selection: String?
    @Binding var isPresented: Bool

    private let columns = [
        GridItem(.adaptive(minimum: 88, maximum: 120), spacing: 18)
    ]

    var body: some View {
        ZStack {
            StoreTheme.canvas
                .opacity(0.97)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            VStack(spacing: 0) {
                HStack {
                    Text("Mini Apps")
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
                            .background(Circle().fill(StoreTheme.surfaceStrong))
                            .overlay(Circle().strokeBorder(StoreTheme.hairlineSoft, lineWidth: 0.5))
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
                Image(systemName: app.icon)
                    .font(.system(size: 26, weight: .medium))
                    .foregroundStyle(.white)
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
        .accessibilityHint(Text("Double tap to jump to \(app.name)"))
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ContentView(miniApps: [
            MiniApp(
                id: "lyricseditor",
                name: "Lyrics Editor",
                tagline: "Write, format, and refine songs",
                icon: "music.note.list",
                tint: Color(red: 0.62, green: 0.52, blue: 1.0)
            ) {
                Text("Lyrics Editor").foregroundStyle(.white)
            },
            MiniApp(
                id: "charactercast",
                name: "Character Cast",
                tagline: "Build casts for your stories",
                icon: "theatermasks.fill",
                tint: Color(red: 1.0, green: 0.55, blue: 0.42)
            ) {
                Text("Character Cast").foregroundStyle(.white)
            }
        ])
    }
}
