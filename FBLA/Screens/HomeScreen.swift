
// Screens/HomeScreen.swift
import SwiftUI
import UIKit

// MARK: - Micro-interaction (press-scale, lightweight)
private struct ScaledButtonStyle: ButtonStyle {
    let scale: CGFloat
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.85), value: configuration.isPressed)
    }
}

// MARK: - Minimal components
private struct IconBadge: View {
    let symbol: String
    let tint: Color
    var body: some View {
        ZStack {
            Circle().fill(tint.opacity(0.15))
            Image(systemName: symbol)
                .foregroundColor(tint)
                .font(.system(size: 16, weight: .semibold))
        }
        .frame(width: 34, height: 34)
        .accessibilityHidden(true)
    }
}

// Small, consistent action buttons (primary & ghost)
private struct PrimaryCapsuleButton: View {
    let title: String
    let symbol: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: symbol)
                Text(title).font(Theme.text(15, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule().fill(
                    LinearGradient(colors: [Theme.red, Theme.red.opacity(0.9)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                )
            )
        }
        .buttonStyle(ScaledButtonStyle(scale: 0.96))
        .accessibilityLabel(Text(title))
    }
}

private struct GhostCapsuleButton: View {
    let title: String
    let symbol: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: symbol)
                Text(title).font(Theme.text(14, weight: .semibold))
            }
            .foregroundColor(Theme.navy)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Capsule().stroke(Theme.navy.opacity(0.25)))
        }
        .buttonStyle(ScaledButtonStyle(scale: 0.97))
        .accessibilityLabel(Text(title))
    }
}

// MARK: - Screen
struct HomeScreen: View {
    @State private var showWelcome = true

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // HERO / BRAND
                Card {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(LinearGradient(colors: [Theme.navy, Theme.navy.opacity(0.85)],
                                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Image(systemName: "graduationcap.fill")
                                        .font(.system(size: 22, weight: .bold))
                                        .foregroundColor(.white)
                                )

                            VStack(alignment: .leading, spacing: 2) {
                                Text("FBLA").font(Theme.display(26)).foregroundColor(Theme.navy)
                                Text("Future Business Leaders of America")
                                    .font(Theme.text(12))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }

                        Text("Home").font(Theme.display(28)).foregroundColor(Theme.navy)

                        HStack(spacing: 10) {
                            PrimaryCapsuleButton(title: "Add Event", symbol: "calendar.badge.plus") {
                                // TODO: navigate to add event
                            }
                            GhostCapsuleButton(title: "Resources", symbol: "book.fill") {
                                // TODO: navigate to resources
                            }
                        }
                    }
                }

                // WELCOME (dismissable)
                if showWelcome {
                    Card {
                        HStack(alignment: .top, spacing: 12) {
                            IconBadge(symbol: "sparkles", tint: Theme.red)
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Welcome").font(Theme.text(17, weight: .semibold))
                                Text("Swipe sections or use tabs. Scroll to see actions and your dashboard.")
                                    .font(Theme.text(13))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Button {
                                withAnimation(.easeInOut(duration: 0.25)) { showWelcome = false }
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.secondary)
                                    .padding(6)
                                    .background(Circle().fill(Color.gray.opacity(0.12)))
                            }
                            .buttonStyle(ScaledButtonStyle(scale: 0.92))
                            .accessibilityLabel(Text("Dismiss"))
                        }
                    }
                    .transition(.opacity.combined(with: .scale))
                }

                // QUICK ACTIONS
                Card {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 12) {
                            IconBadge(symbol: "bolt.fill", tint: Theme.red)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Quick Actions").font(Theme.text(17, weight: .semibold))
                                Text("Start timer, add task, open resources")
                                    .font(Theme.text(13))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        HStack(spacing: 10) {
                            PrimaryCapsuleButton(title: "Start Timer", symbol: "timer") {
                                // TODO: start timer
                            }
                            GhostCapsuleButton(title: "Add Task", symbol: "checklist") {
                                // TODO: add task
                            }
                            GhostCapsuleButton(title: "Resources", symbol: "bookmark.fill") {
                                // TODO: open resources
                            }
                        }
                    }
                }

                // DASHBOARD
                Card(dense: true) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Dashboard").font(Theme.text(17, weight: .semibold))
                        HStack(spacing: 8) {
                            dashChip("Events", "calendar")
                            dashChip("Tasks", "checklist")
                            dashChip("Resources", "book.closed")
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
            }
            .padding(16)
        }
        .background(Color(uiColor: .systemBackground))
        .navigationBarTitleDisplayMode(.inline)
    }

    // Minimal chip helper
    private func dashChip(_ title: String, _ symbol: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: symbol).font(.system(size: 14, weight: .semibold))
            Text(title).font(Theme.text(13, weight: .semibold))
        }
        .foregroundColor(.primary)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Capsule().fill(Color.gray.opacity(0.12)))
        .overlay(Capsule().stroke(Theme.border))
    }
}

// MARK: - Preview
struct HomeScreen_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView { HomeScreen() }.preferredColorScheme(.light)
        NavigationView { HomeScreen() }.preferredColorScheme(.dark)
    }
}
