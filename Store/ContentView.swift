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

    @State private var selection: String

    init(miniApps: [MiniApp]) {
        self.miniApps = miniApps
        _selection = State(initialValue: miniApps.first?.id ?? "")
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.ignoresSafeArea()

            TabView(selection: $selection) {
                ForEach(miniApps) { app in
                    MiniAppWorld(app: app)
                        .tag(app.id)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea(.container, edges: .horizontal)

            indicator
                .padding(.bottom, 28)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationDestination(for: MiniApp.self) { app in
            app.destination()
        }
        .preferredColorScheme(.dark)
    }

    private var indicator: some View {
        HStack(spacing: 6) {
            ForEach(miniApps) { app in
                Capsule()
                    .fill(
                        selection == app.id
                            ? Color.white
                            : Color.white.opacity(0.20)
                    )
                    .frame(width: selection == app.id ? 22 : 6, height: 6)
                    .animation(.spring(response: 0.35, dampingFraction: 0.85), value: selection)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .opacity(0.85)
        )
        .overlay(
            Capsule()
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5)
        )
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
                    .font(.system(size: 42, weight: .bold))
                    .foregroundStyle(.white)
                    .tracking(-1.0)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 12)

                Text(app.tagline)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white.opacity(0.65))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                Spacer(minLength: 40)

                NavigationLink(value: app) {
                    openButton
                }
                .buttonStyle(WorldButtonStyle())
                .padding(.bottom, 110)
            }
        }
    }

    private var atmosphere: some View {
        ZStack {
            Color.black

            RadialGradient(
                colors: [
                    app.tint.opacity(0.55),
                    app.tint.opacity(0.18),
                    Color.clear
                ],
                center: UnitPoint(x: 0.5, y: 0.32),
                startRadius: 20,
                endRadius: 440
            )

            RadialGradient(
                colors: [app.tint.opacity(0.28), Color.clear],
                center: UnitPoint(x: 0.85, y: 0.9),
                startRadius: 0,
                endRadius: 280
            )

            RadialGradient(
                colors: [app.tint.opacity(0.22), Color.clear],
                center: UnitPoint(x: 0.12, y: 0.88),
                startRadius: 0,
                endRadius: 240
            )

            RadialGradient(
                colors: [Color.clear, Color.black.opacity(0.45)],
                center: .center,
                startRadius: 220,
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
                            app.tint.opacity(0.70)
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
    }

    private var openButton: some View {
        HStack(spacing: 10) {
            Text("Open")
                .font(.system(size: 15, weight: .semibold))
            Image(systemName: "arrow.right")
                .font(.system(size: 13, weight: .bold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 26)
        .padding(.vertical, 15)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
        )
        .overlay(
            Capsule()
                .strokeBorder(Color.white.opacity(0.22), lineWidth: 0.6)
        )
        .shadow(color: app.tint.opacity(0.35), radius: 18, y: 8)
    }
}

// MARK: - Style

private struct WorldButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
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
