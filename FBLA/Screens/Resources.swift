//
//  Resources.swift
//  FBLA
//
//  Refactored Resources screen (static list + chips + frosted search)
//  Swift 6 + iOS 17
//

import SwiftUI

/// A browseable list of common resources with chips and a frosted search placeholder.
struct Resources: View {

    /// Category chips (decorative).
    private let categories = ["Guides", "Documents", "Competition", "Templates"]

    /// Example resources shown as a simple list.
    private let resources: [ResourceItem] = [
        .init(id: 1, title: "FBLA Handbook",        detail: "PDF • 2.1 MB • Updated Jan 2026", icon: "book.closed.fill",      accent: .blue),
        .init(id: 2, title: "Competition Rules",     detail: "PDF • 1.3 MB • 2026 Season",      icon: "checkmark.seal.fill",   accent: .green),
        .init(id: 3, title: "Speech Template",       detail: "DOCX • 86 KB",                    icon: "doc.text.fill",         accent: .orange),
        .init(id: 4, title: "Practice Schedule",     detail: "Calendar • Subscribe",             icon: "calendar.badge.clock",  accent: .purple)
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
                            if item.id != resources.last?.id {
                                Divider().opacity(0.2)
                            }
                        }
                    }
                }
            }
            .padding(16)
        }
    }
}

// MARK: - Models & Rows

/// A simple resource item (static list demo).
private struct ResourceItem: Identifiable {
    let id: Int
    let title: String
    let detail: String
    let icon: String
    let accent: Color
}

/// A single resource row with accent square icon and chevron.
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
                Text(item.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(item.detail)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
            Image(systemName: "chevron.right").foregroundColor(.secondary)
        }
    }
}

/// A small pill chip for categories.
private struct Chip: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.caption)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(Color.gray.opacity(0.12)))
            .overlay(Capsule().stroke(Color.gray.opacity(0.18)))
    }
}

/// A frosted search bar stub that feels native without wiring.
private struct SearchBarPlaceholder: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundColor(.secondary)
            Text("Search resources").foregroundColor(.secondary)
            Spacer()
        }
        .padding(10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.white.opacity(0.28).blendMode(.overlay), lineWidth: 1)
        )
    }
}
