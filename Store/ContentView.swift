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

struct ContentView: View {
    let miniApps: [MiniApp]

    @State private var selection: String?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(miniApps: [MiniApp]) {
        self.miniApps = miniApps
        _selection = State(initialValue: miniApps.first?.id)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.ignoresSafeArea()

            worldsScroller

            indicator
                .padding(.bottom, 24)
                .accessibilityHidden(true)
        }
        .sensoryFeedback(.selection, trigger: selection)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationDestination(for: MiniApp.self) { app in
            app.destination()
        }
        .preferredColorScheme(.dark)
    }

    private var worldsScroller: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 0) {
                ForEach(miniApps) { app in
                    MiniAppWorld(app: app)
                        .containerRelativeFrame(.horizontal)
                        .id(app.id)
                        .scrollTransition(axis: .horizontal) { content, phase in
                            content
                                .opacity(reduceMotion ? 1 : (phase.isIdentity ? 1 : 0.35))
                                .scaleEffect(reduceMotion ? 1 : (phase.isIdentity ? 1 : 0.94))
                        }
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $selection)
        .scrollIndicators(.hidden)
    }

    private var indicator: some View {
        HStack(spacing: 6) {
            ForEach(miniApps) { app in
                Capsule()
                    .fill(
                        selection == app.id
                            ? Color.white
                            : Color.white.opacity(0.22)
                    )
                    .frame(width: selection == app.id ? 22 : 6, height: 6)
                    .animation(.spring(response: 0.35, dampingFraction: 0.85), value: selection)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .glassEffect(.regular, in: .capsule)
    }
}

// MARK: - World

private struct MiniAppWorld: View {
    let app: MiniApp

    var body: some View {
        ZStack {
            atmosphere

            VStack(spacing: 0) {
                Spacer(minLength: 40)

                iconBadge
                    .padding(.bottom, 40)

                Text(app.name)
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(.white)
                    .tracking(-0.8)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 12)
                    .dynamicTypeSize(...DynamicTypeSize.accessibility1)

                Text(app.tagline)
                    .font(.callout.weight(.medium))
                    .foregroundStyle(.white.opacity(0.68))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .dynamicTypeSize(...DynamicTypeSize.accessibility2)

                Spacer(minLength: 40)

                openLink
                    .padding(.bottom, 108)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(app.name). \(app.tagline)")
        .accessibilityAddTraits(.isHeader)
    }

    private var atmosphere: some View {
        ZStack {
            MeshGradient(
                width: 3,
                height: 3,
                points: [
                    [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                    [0.0, 0.5], [0.5, 0.32], [1.0, 0.5],
                    [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
                ],
                colors: [
                    .black,
                    app.tint.opacity(0.60),
                    .black,
                    app.tint.opacity(0.32),
                    app.tint.opacity(0.78),
                    app.tint.opacity(0.22),
                    .black,
                    app.tint.opacity(0.18),
                    .black
                ]
            )

            RadialGradient(
                colors: [.clear, .black.opacity(0.40)],
                center: .center,
                startRadius: 240,
                endRadius: 620
            )
        }
        .ignoresSafeArea()
    }

    private var iconBadge: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            app.tint,
                            app.tint.opacity(0.72)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .strokeBorder(Color.white.opacity(0.25), lineWidth: 0.8)
            Image(systemName: app.icon)
                .font(.system(size: 56, weight: .semibold))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
        }
        .frame(width: 124, height: 124)
        .shadow(color: app.tint.opacity(0.55), radius: 44, y: 16)
        .shadow(color: .black.opacity(0.45), radius: 20, y: 12)
        .accessibilityHidden(true)
    }

    private var openLink: some View {
        NavigationLink(value: app) {
            HStack(spacing: 10) {
                Text("Open")
                    .font(.subheadline.weight(.semibold))
                Image(systemName: "arrow.right")
                    .font(.footnote.weight(.bold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 26)
            .padding(.vertical, 15)
            .glassEffect(.regular.tint(app.tint).interactive(), in: .capsule)
        }
        .buttonStyle(.plain)
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
