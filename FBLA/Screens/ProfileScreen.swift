
// Screens/ProfileScreen.swift
import SwiftUI

struct ProfileScreen: View {
    private let stats: [StatItem] = [
        .init(id: 1, title: "Events", value: "12", icon: "calendar"),
        .init(id: 2, title: "Hours", value: "24", icon: "clock"),
        .init(id: 3, title: "Awards", value: "3", icon: "rosette")
    ]

    private let prefs: [PrefItem] = [
        .init(id: 1, title: "Notifications", detail: "Announcements & Updates", icon: "bell.fill"),
        .init(id: 2, title: "Email", detail: "akshar@example.com", icon: "envelope.fill"),
        .init(id: 3, title: "Membership", detail: "Active • Expires Jun 2026", icon: "person.badge.shield.checkmark")
    ]

    private let badges: [BadgeItem] = [
        .init(id: 1, text: "Regionals 2026"),
        .init(id: 2, text: "Volunteer 20h"),
        .init(id: 3, text: "Chapter Lead")
    ]

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                SectionTitle(title: "Profile")

                // Header
                Card {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle().fill(Color.accentColor.opacity(0.15))
                            Image(systemName: "person.fill").foregroundColor(.accentColor)
                        }
                        .frame(width: 48, height: 48)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Akshar Tamhankar").font(.headline)
                            Text("FBLA Member • Forsyth County, GA")
                                .font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "square.and.pencil").foregroundColor(.secondary)
                    }
                }

                // Stats
                Card {
                    HStack(spacing: 12) {
                        ForEach(stats) { s in
                            StatTile(item: s)
                            if s.id != stats.last?.id { Divider().opacity(0.2) }
                        }
                    }
                }

                // Preferences
                Card {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Preferences").font(.headline)
                        ForEach(prefs) { p in
                            PrefRow(item: p)
                            if p.id != prefs.last?.id { Divider().opacity(0.2) }
                        }
                    }
                }

                // Badges
                Card {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Badges").font(.headline)
                        FlowLayout(spacing: 8) {
                            ForEach(badges) { b in BadgeChip(b.text) }
                        }
                    }
                }
            }
            .padding(16)
        }
    }
}

// MARK: - Models
private struct StatItem: Identifiable {
    let id: Int
    let title: String
    let value: String
    let icon: String
}

private struct PrefItem: Identifiable {
    let id: Int
    let title: String
    let detail: String
    let icon: String
}

private struct BadgeItem: Identifiable {
    let id: Int
    let text: String
}

// MARK: - Rows / Tiles
private struct StatTile: View {
    let item: StatItem
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: item.icon).foregroundColor(.accentColor)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.value).font(.subheadline).fontWeight(.semibold)
                Text(item.title).font(.caption).foregroundColor(.secondary)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct PrefRow: View {
    let item: PrefItem
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8).fill(Color.accentColor.opacity(0.12))
                Image(systemName: item.icon).foregroundColor(.accentColor)
            }
            .frame(width: 36, height: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title).font(.subheadline).fontWeight(.semibold)
                Text(item.detail).font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundColor(.secondary)
        }
    }
}

private struct BadgeChip: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text)
            .font(.caption)
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(Capsule().fill(Color.gray.opacity(0.12)))
            .overlay(Capsule().stroke(Color.gray.opacity(0.18)))
    }
}

// MARK: - Lightweight Flow Layout for chips
private struct FlowLayout<Content: View>: View {
    let spacing: CGFloat
    @ViewBuilder var content: () -> Content

    init(spacing: CGFloat = 8, @ViewBuilder content: @escaping () -> Content) {
        self.spacing = spacing
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            HStack(spacing: spacing) { content() }
        }
    }
}
