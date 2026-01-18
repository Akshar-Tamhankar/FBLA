
// Screens/ContentView.swift
import SwiftUI

enum AppSection: Int, CaseIterable { case home, calendar, news, resources, profile }

struct ContentView: View {
    @State private var index: Int = 0
    private let count = AppSection.allCases.count

    // Build hosting controllers once (stable, efficient)
    private let controllers: [UIViewController] = [
        UIHostingController(rootView: HomeScreen()),
        UIHostingController(rootView: CalendarScreen()),
        UIHostingController(rootView: NewsScreen()),
        UIHostingController(rootView: ResourcesScreen()),
        UIHostingController(rootView: ProfileScreen())
    ]

    var body: some View {
        InfinitePager(controllers: controllers, index: $index)
            // Bottom pill overlay (non-intrusive; respects safe area)
            .pillPageIndicator(
                count: count,
                selectedIndex: $index,
                bottomPadding: 12,
                ignoreBottomSafeArea: false
            )
            .ignoresSafeArea(edges: .bottom)
    }
}
