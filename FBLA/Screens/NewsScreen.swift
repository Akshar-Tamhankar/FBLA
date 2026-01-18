
// Screens/NewsScreen.swift
import SwiftUI

struct NewsScreen: View {
    private let posts: [NewsPost] = [
        .init(title: "FBLA Regionals Announced", summary: "Registration opens next week. Check eligibility and deadlines.", date: "Jan 12, 2026", tag: "Announcement", icon: "megaphone.fill", accent: .blue),
        .init(title: "Practice Schedule Updated", summary: "New sessions on Tue/Thu. Bring laptops and notebooks.", date: "Jan 10, 2026", tag: "Update", icon: "calendar.badge.clock", accent: .orange),
        .init(title: "Volunteer Opportunity", summary: "Help at Saturday workshop. Earn hours and leadership credit.", date: "Jan 9, 2026", tag: "Service", icon: "hands.sparkles.fill", accent: .purple)
    ]

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                SectionTitle(title: "News")

                // Header
                Card {
                    HStack(spacing: 12) {
                        Label("Feed", systemImage: "newspaper.fill")
                            .font(.headline)
                        Spacer()
                        Capsule()
                            .fill(Color.gray.opacity(0.12))
                            .frame(height: 32)
                            .overlay(
                                HStack(spacing: 12) {
                                    Text("All").font(.caption).padding(.horizontal, 8)
                                    Divider().frame(height: 16)
                                    Text("Announcements").font(.caption)
                                    Divider().frame(height: 16)
                                    Text("Updates").font(.caption)
                                }
                                .foregroundColor(.secondary)
                            )
                    }
                }

                // Posts
                ForEach(posts) { post in
                    Card { PostRow(post: post) }
                }
            }
            .padding(16)
        }
    }
}

// MARK: - Models & Rows
private struct NewsPost: Identifiable {
    let id = UUID()
    let title: String
    let summary: String
    let date: String
    let tag: String
    let icon: String
    let accent: Color
}

private struct PostRow: View {
    let post: NewsPost
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(post.accent.opacity(0.15))
                    Image(systemName: post.icon).foregroundColor(post.accent)
                }
                .frame(width: 32, height: 32)
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.title).font(.subheadline).fontWeight(.semibold)
                    Text(post.summary).font(.caption).foregroundColor(.secondary)
                }
                Spacer()
            }
            HStack(spacing: 8) {
                Tag(post.tag)
                Text("•").foregroundColor(.secondary)
                Text(post.date).font(.caption).foregroundColor(.secondary)
                Spacer()
                Image(systemName: "chevron.right").foregroundColor(.secondary)
            }
        }
    }
}

private struct Tag: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text)
            .font(.caption2)
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(Capsule().fill(Color.gray.opacity(0.12)))
            .overlay(Capsule().stroke(Color.gray.opacity(0.18)))
    }
}
