//
//  StoreApp.swift
//  Store
//
//  Created by u on 21/06/2026.
//

import SwiftUI

@main
struct StoreApp: App {
    var body: some Scene {
        WindowGroup {
            TabView {
                Tab("Home", systemImage: "house.fill") {
                    PlaceholderTab(title: "Home", icon: "house.fill")
                }

                Tab("Apps", systemImage: "square.grid.2x2.fill") {
                    NavigationStack {
                        ContentView(miniApps: demoMiniApps)
                    }
                }

                Tab("Profile", systemImage: "person.crop.circle.fill") {
                    PlaceholderTab(title: "Profile", icon: "person.crop.circle.fill")
                }
            }
            .preferredColorScheme(.dark)
        }
    }

    private var demoMiniApps: [MiniApp] {
        [
            MiniApp(
                id: "lyricseditor",
                name: "Lyrics Editor",
                tagline: "Write, format, and refine songs",
                systemImage: "music.note.list",
                tint: Color(red: 0.62, green: 0.52, blue: 1.0)
            ) {
                DemoBody(title: "Lyrics Editor", icon: "music.note.list", tint: Color(red: 0.62, green: 0.52, blue: 1.0))
            },
            MiniApp(
                id: "charactercast",
                name: "Character Cast",
                tagline: "Build casts for your stories",
                systemImage: "theatermasks.fill",
                tint: Color(red: 1.0, green: 0.55, blue: 0.42)
            ) {
                DemoBody(title: "Character Cast", icon: "theatermasks.fill", tint: Color(red: 1.0, green: 0.55, blue: 0.42))
            },
            MiniApp(
                id: "moodboard",
                name: "Moodboard",
                tagline: "Collect references and palettes",
                systemImage: "rectangle.grid.2x2.fill",
                tint: Color(red: 1.0, green: 0.45, blue: 0.75)
            ) {
                DemoBody(title: "Moodboard", icon: "rectangle.grid.2x2.fill", tint: Color(red: 1.0, green: 0.45, blue: 0.75))
            },
            MiniApp(
                id: "scenebuilder",
                name: "Scene Builder",
                tagline: "Storyboard scenes and beats",
                systemImage: "film.fill",
                tint: Color(red: 0.35, green: 0.85, blue: 0.95)
            ) {
                DemoBody(title: "Scene Builder", icon: "film.fill", tint: Color(red: 0.35, green: 0.85, blue: 0.95))
            },
            MiniApp(
                id: "voicenotes",
                name: "Voice Notes",
                tagline: "Capture ideas on the fly",
                systemImage: "waveform",
                tint: Color(red: 0.55, green: 0.95, blue: 0.70)
            ) {
                DemoBody(title: "Voice Notes", icon: "waveform", tint: Color(red: 0.55, green: 0.95, blue: 0.70))
            },
            MiniApp(
                id: "rhymefinder",
                name: "Rhyme Finder",
                tagline: "Search rhymes and syllables",
                systemImage: "text.magnifyingglass",
                tint: Color(red: 1.0, green: 0.80, blue: 0.35)
            ) {
                DemoBody(title: "Rhyme Finder", icon: "text.magnifyingglass", tint: Color(red: 1.0, green: 0.80, blue: 0.35))
            },
            MiniApp(
                id: "setlist",
                name: "Setlist",
                tagline: "Plan and order performances",
                systemImage: "list.number",
                tint: Color(red: 0.50, green: 0.70, blue: 1.0)
            ) {
                DemoBody(title: "Setlist", icon: "list.number", tint: Color(red: 0.50, green: 0.70, blue: 1.0))
            },
            MiniApp(
                id: "metronome",
                name: "Metronome",
                tagline: "Tap, tempo, and time signatures",
                systemImage: "metronome.fill",
                tint: Color(red: 0.95, green: 0.45, blue: 0.55)
            ) {
                DemoBody(title: "Metronome", icon: "metronome.fill", tint: Color(red: 0.95, green: 0.45, blue: 0.55))
            },
            MiniApp(
                id: "archive",
                name: "Archive",
                tagline: "Browse past sessions and drafts",
                systemImage: "archivebox.fill",
                tint: Color(red: 0.80, green: 0.75, blue: 0.95)
            ) {
                DemoBody(title: "Archive", icon: "archivebox.fill", tint: Color(red: 0.80, green: 0.75, blue: 0.95))
            },
            MiniApp(
                id: "settings",
                name: "Account & Settings",
                tagline: "Profile, sync, and preferences",
                systemImage: "gearshape.fill",
                tint: Color(red: 0.70, green: 0.70, blue: 0.75)
            ) {
                DemoBody(title: "Account & Settings", icon: "gearshape.fill", tint: Color(red: 0.70, green: 0.70, blue: 0.75))
            }
        ]
    }
}

// MARK: - Placeholder tabs (siblings of the mini-app picker)

private struct PlaceholderTab: View {
    let title: String
    let icon: String

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.04, green: 0.04, blue: 0.05).ignoresSafeArea()
                VStack(spacing: 14) {
                    Image(systemName: icon)
                        .font(.system(size: 40, weight: .medium))
                        .foregroundStyle(.white.opacity(0.35))
                    Text(title)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            .navigationTitle(title)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

// MARK: - Demo destination (pushed when an app is opened)

private struct DemoBody: View {
    let title: String
    let icon: String
    let tint: Color

    var body: some View {
        ZStack {
            Color(red: 0.04, green: 0.04, blue: 0.05).ignoresSafeArea()
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 46, weight: .semibold))
                    .foregroundStyle(tint)
                Text(title)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
                Text("Mini app destination")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.45))
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}
