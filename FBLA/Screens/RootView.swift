
// Screens/RootView.swift
import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [Profile]

    private var profile: Profile? { profiles.first }
    private var isComplete: Bool { profile?.didCompleteSetup == true }

    var body: some View {
        Group {
            if isComplete {
                ContentView()
                    .id("content-\(profile?.preferredAppearanceRaw ?? "system")")
            } else {
                OnboardingFlowView()
                    .id("onboard-\(profile?.preferredAppearanceRaw ?? "system")")
            }
        }
        // 🔹 App‑wide frosted cards
        .cardStyle(.frosted)

        // Keep your appearance override + rebuild keys
        .preferredColorScheme(profile?.preferredColorScheme)
        .id("complete-\(isComplete ? 1 : 0)")

        .task {
            AppDelegate.modelContextProvider = { [weak modelContext] in modelContext }
            if profiles.isEmpty {
                let p = Profile.defaultProfile()
                modelContext.insert(p)
                try? modelContext.save()
            }
        }
    }
}
