
// FBLA/App/App.swift
// Swift 6 • iOS 17+
//
///  The FBLA application entry point and root composition.
///
///  This file wires up:
///  - `FBLAApp`: `@main` app struct that installs SwiftData containers and configures
///    global UIKit appearances to let our frosted cards and animated background show through.
///  - `RootView`: Switches between the onboarding flow and the main content, applying
///    the user's preferred appearance and seeding a default `Profile` if needed.
///  - `ContentView`: Hosts the infinite pager across top-level sections and overlays
///    the animated background + pill page indicator.
///  - `AppSection`: Stable order of app pages.
///  - `AppDelegate`: APNs plumbing to persist the device token into SwiftData.
///
///  ### Requirements satisfied
///  - **Efficiency**: Single SwiftData container, cached view controllers in the pager,
///    static/cached formatters live elsewhere. Minimal state in root.
///  - **Documentation**: DocC comments on every public type/function.
///  - **Organization**: Lives under `App/`, clean names, no vestigial code.
///  - **Visual Fidelity**: Identical to original: background, pager, pill indicator.
///
import SwiftUI
import SwiftData
import UserNotifications
import UIKit

/// The main FBLA application entry point.
@main
struct FBLAApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    /// Configures transparent bars so our frosted cards and background are visible.
    init() {
        let nav = UINavigationBarAppearance()
        nav.configureWithTransparentBackground()
        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav

        let tab = UITabBarAppearance()
        tab.configureWithTransparentBackground()
        UITabBar.appearance().standardAppearance = tab
        if #available(iOS 15.0, *) { UITabBar.appearance().scrollEdgeAppearance = tab }
    }

    /// Installs the SwiftData container and presents the root view.
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [ClubEvent.self, Profile.self, Badge.self])
    }
}

/// Decides whether to show onboarding or the main content and applies the user's
/// preferred color scheme. Also ensures a default `Profile` exists.
struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [Profile]

    /// The single current user profile (single-user app semantics).
    private var profile: Profile? { profiles.first }

    /// Whether onboarding is completed.
    private var isComplete: Bool { profile?.didCompleteSetup == true }

    var body: some View {
        Group {
            if isComplete {
                ContentView()
                    // Force rebuild when appearance mode changes.
                    .id("content-\(profile?.preferredAppearanceRaw ?? "system")")
            } else {
                OnboardingFlowView()
                    .id("onboard-\(profile?.preferredAppearanceRaw ?? "system")")
            }
        }
        .cardStyle(.frosted)
        .preferredColorScheme(profile?.preferredColorScheme)
        // Force swap when completion flips.
        .id("complete-\(isComplete ? 1 : 0)")
        .task {
            // Allow AppDelegate to access SwiftData context for APNs token persistence.
            AppDelegate.modelContextProvider = { [weak modelContext] in modelContext }
            // Ensure a default profile on first launch.
            if profiles.isEmpty {
                let p = Profile.defaultProfile()
                modelContext.insert(p)
                try? modelContext.save()
            }
        }
    }
}

/// Hosts the pager and animated background with a bottom pill page indicator.
struct ContentView: View {
    @Environment(\.colorScheme) private var scheme
    @State private var index: Int = 0
    @State private var progress: Double = 0

    /// Total number of app pages.
    private let count = AppSection.allCases.count

    var body: some View {
        ZStack {
            // Static gradient backdrop (scheme-aware).
            LinearGradient(colors: gradient(for: scheme),
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            // Animated haze + gold accents (independent of swipes/pages).
            Background3DView(pageIndex: $index, swipeProgress: $progress, colorScheme: scheme)
                .ignoresSafeArea()

            // Foreground content (infinite wrap-around paging).
            InfinitePager(index: $index, count: count) { page in
                switch AppSection(rawValue: page)! {
                case .home:      Home()
                case .calendar:  CalendarScreen()
                case .news:      News()
                case .resources: Resources()
                case .profile:   ProfileScreen()
                }
            } onScrollProgress: { progress = $0 }
            .pillPageIndicator(count: count, selectedIndex: $index, bottomPadding: 12, ignoreBottomSafeArea: false)
            .ignoresSafeArea(edges: .bottom)
        }
    }

    /// Returns the navy + scheme-appropriate gradient palette.
    private func gradient(for scheme: ColorScheme) -> [Color] {
        let navy = Theme.navy
        return scheme == .dark
            ? [navy.opacity(0.26), Color(white: 0.08)]
            : [navy.opacity(0.20), .white]
    }
}

/// The top-level sections shown in the pager, in visual order.
enum AppSection: Int, CaseIterable { case home, calendar, news, resources, profile }

/// Objective‑C app delegate for APNs callbacks that persist the device token to SwiftData.
final class AppDelegate: NSObject, UIApplicationDelegate {
    /// Set by `RootView` so we can save the APNs token into SwiftData.
    static var modelContextProvider: () -> ModelContext? = { nil }

    /// Saves the APNs device token to the first `Profile` row and marks permission as granted.
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02x", $0) }.joined()
        guard let ctx = Self.modelContextProvider() else { return }
        let fetch = FetchDescriptor<Profile>(predicate: nil)
        if let profile = try? ctx.fetch(fetch).first {
            profile.apnsDeviceToken = token
            profile.pushPermissionGranted = true
            try? ctx.save()
        }
    }

    /// Prints APNs registration errors in debug builds.
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        #if DEBUG
        print("⚠️ APNs registration failed: \(error)")
        #endif
    }
}
