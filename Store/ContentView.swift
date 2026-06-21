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
    @Namespace private var zoomNamespace
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.horizontalSizeClass) private var sizeClass

    init(miniApps: [MiniApp]) {
        self.miniApps = miniApps
        _selection = State(initialValue: miniApps.first?.id)
    }

    var body: some View {
        Group {
            if sizeClass == .regular {
                regularLayout
            } else {
                compactLayout
            }
        }
        .background(StoreTheme.canvas.ignoresSafeArea())
        .sensoryFeedback(.selection, trigger: selection)
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
                        namespace: zoomNamespace
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
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $selection)
        .scrollIndicators(.hidden)
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
                        namespace: zoomNamespace
                    )
                    .id(app.id)
                    .transition(reduceMotion ? .opacity : .opacity)
                }
            }
            .animation(.easeOut(duration: 0.25), value: selection)
        }
    }

    private var sidebar: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 2) {
                Text("Mini Apps")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
                    .tracking(-0.4)
                    .padding(.horizontal, 16)
                    .padding(.top, 28)
                    .padding(.bottom, 4)

                Text("\(miniApps.count) apps")
                    .font(.footnote)
                    .foregroundStyle(StoreTheme.mutedSoft)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)

                ForEach(miniApps) { app in
                    Button {
                        withAnimation(.easeOut(duration: 0.18)) {
                            selection = app.id
                        }
                    } label: {
                        SidebarRow(app: app, isSelected: selection == app.id)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 20)
        }
        .background(StoreTheme.canvas)
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

    var body: some View {
        ZStack {
            StoreTheme.canvas.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 40)

                iconBadge
                    .matchedTransitionSource(id: app.id, in: namespace)
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(app.name). \(app.tagline)")
        .accessibilityHint("Double tap to open \(app.name)")
        .accessibilityAddTraits(.isHeader)
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
        .accessibilityLabel("Open \(app.name)")
        .accessibilityAddTraits(.isButton)
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
