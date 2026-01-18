
// Screens/ResourcesScreen.swift
import SwiftUI

struct ResourcesScreen: View {
    private let categories = ["Guides", "Documents", "Competition", "Templates"]
    // Use stable IDs (Int) instead of UUID to avoid extra diffing work
    private let resources: [ResourceItem] = [
        .init(id: 1, title: "FBLA Handbook", detail: "PDF • 2.1 MB • Updated Jan 2026", icon: "book.closed.fill", accent: .blue),
        .init(id: 2, title: "Competition Rules", detail: "PDF • 1.3 MB • 2026 Season", icon: "checkmark.seal.fill", accent: .green),
        .init(id: 3, title: "Speech Template", detail: "DOCX • 86 KB", icon: "doc.text.fill", accent: .orange),
        .init(id: 4, title: "Practice Schedule", detail: "Calendar • Subscribe", icon: "calendar.badge.clock", accent: .purple)
    ]

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                SectionTitle(title: "Resources")

                // Search + header
                Card {
                    VStack(spacing: 12) {
                        HStack {
                            Label("Browse", systemImage: "folder.fill")
                                .font(.headline)
                            Spacer()
                            Image(systemName: "slider.horizontal.3")
                                .foregroundColor(.secondary)
                        }
                        SearchBarPlaceholder()
                    }
                }

                // Category chips
                Card {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(categories, id: \.self) { cat in Chip(cat) }
                        }
                        .padding(.vertical, 4)
                    }
                }

                // Resource list
                Card {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Common Resources").font(.headline)
                        ForEach(resources) { item in
                            ResourceRow(item: item)
                            if item.id != resources.last?.id { Divider().opacity(0.2) }
                        }
                    }
                }
            }
            .padding(16)
        }
    }
}

// MARK: - Models & Rows
private struct ResourceItem: Identifiable {
    let id: Int
    let title: String
    let detail: String
    let icon: String
    let accent: Color
}

private struct ResourceRow: View {
    let item: ResourceItem
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8).fill(item.accent.opacity(0.15))
                Image(systemName: item.icon).foregroundColor(item.accent)
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

private struct Chip: View {
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

private struct SearchBarPlaceholder: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundColor(.secondary)
            Text("Search resources").foregroundColor(.secondary)
            Spacer()
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.15))
        )
    }
}
