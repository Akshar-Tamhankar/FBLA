
// Screens/ContentView.swift
import SwiftUI

enum AppSection: Int, CaseIterable { case home, calendar, news, resources, profile }

struct ContentView: View {
    @Environment(\.colorScheme) private var scheme
    @State private var index: Int = 0
    @State private var progress: Double = 0
    private let count = AppSection.allCases.count

    var body: some View {
        ZStack {
            // 1) Static navy gradient backdrop (not tied to page)
            LinearGradient(colors: gradient(for: index, scheme), // idx ignored by function
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .ignoresSafeArea()

            // 2) Bubbles (passive)
            Background3DView(pageIndex: $index, swipeProgress: $progress, colorScheme: scheme)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()

            // 3) Foreground content: InfinitePager + cards
            InfinitePager(index: $index, count: count) { i in
                switch AppSection(rawValue: i)! {
                case .home:      HomeScreen()
                case .calendar:  CalendarScreen()
                case .news:      NewsScreen()
                case .resources: ResourcesScreen()
                case .profile:   ProfileScreen()
                }
            } onScrollProgress: { p in
                // Bubbles are decoupled; we still track p for your pill indicator if needed
                progress = p
            }
            .pillPageIndicator(
                count: count,
                selectedIndex: $index,
                bottomPadding: 12,
                ignoreBottomSafeArea: false
            )
            .ignoresSafeArea(edges: .bottom)
        }
    }

    // Static navy palette (idx ignored)
    private func gradient(for _: Int, _ scheme: ColorScheme) -> [Color] {
        // Use your Theme.navy if desired
        let navy = Color(.sRGB, red: 11/255, green: 45/255, blue: 107/255, opacity: 1)
        if scheme == .dark {
            // navy → deep navy
            return [navy.opacity(0.26), Color(white: 0.08)]
        } else {
            // light navy tint → white
            return [navy.opacity(0.20), .white]
        }
    }
}
