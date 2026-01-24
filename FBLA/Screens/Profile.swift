
// FBLA/Screens/Profile.swift
// Swift 6 • iOS 17+
//
///  Profile screen: identity header, dashboard stats, preferences, badges, and an edit sheet.
///
import SwiftUI
import SwiftData

/// The Profile page with preferences, badges, and quick edit sheet.
struct ProfileScreen: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [Profile]
    @Query(sort: \ClubEvent.date) private var allEvents: [ClubEvent]

    @State private var showEdit = false
    @State private var showAddBadge = false
    @State private var newBadgeLabel = ""

    private var profile: Profile? { profiles.first }
    private var eventsCount: Int { allEvents.count }
    private var hoursCount: String {
        let v = profile?.serviceHours ?? 0
        return v == floor(v) ? String(Int(v)) : String(format: "%.1f", v)
    }
    private var awardsCount: Int { profile?.badges.count ?? 0 }

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
                            Text(profile?.fullName ?? "—").font(.headline)
                            Text(headerSubtitle).font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                        Button { showEdit = true } label: {
                            Image(systemName: "square.and.pencil").foregroundColor(.secondary)
                        }
                        .accessibilityLabel(Text("Edit Profile"))
                    }
                }

                // Dashboard
                Card {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Dashboard").font(.headline)
                        HStack(spacing: 12) {
                            StatTile(title: "Events", value: "\(eventsCount)", icon: "calendar")
                            Divider().opacity(0.2)
                            StatTile(title: "Hours", value: hoursCount, icon: "clock")
                            Divider().opacity(0.2)
                            StatTile(title: "Awards", value: "\(awardsCount)", icon: "rosette")
                        }
                    }
                }

                // Preferences
                Card {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Preferences").font(.headline)
                        if let p = profile {
                            ToggleRow(
                                title: "Announcements",
                                subtitle: "News & chapter messages",
                                systemImage: "bell.badge.fill",
                                isOn: Binding(get: { p.notifyAnnouncements }, set: { p.notifyAnnouncements = $0; save() })
                            )
                            Divider().opacity(0.2)
                            ToggleRow(
                                title: "Updates",
                                subtitle: "Schedule & practice changes",
                                systemImage: "calendar.badge.clock",
                                isOn: Binding(get: { p.notifyUpdates }, set: { p.notifyUpdates = $0; save() })
                            )
                            Divider().opacity(0.2)
                            EditableRow(title: "Email", value: p.email, systemImage: "envelope.fill") { new in p.email = new; save() }
                            Divider().opacity(0.2)
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8).fill(Color.accentColor.opacity(0.12))
                                    Image(systemName: "person.badge.shield.checkmark").foregroundColor(.accentColor)
                                }
                                .frame(width: 36, height: 36)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Membership").font(.subheadline).fontWeight(.semibold)
                                    Text(membershipText(p.membershipExpiration)).font(.caption).foregroundColor(.secondary)
                                }
                                Spacer()
                                Button { showEdit = true } label: {
                                    Image(systemName: "chevron.right").foregroundColor(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                        } else {
                            Text("Loading…").foregroundColor(.secondary)
                        }
                    }
                }

                // Badges
                Card {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Badges").font(.headline)
                            Spacer()
                            Button { showAddBadge = true } label: {
                                Label("Add", systemImage: "plus").labelStyle(.iconOnly)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(Text("Add Badge"))
                        }

                        if let p = profile, !p.badges.isEmpty {
                            FlowLayout(spacing: 8) {
                                ForEach(Array(p.badges.enumerated()), id: \.offset) { idx, b in
                                    BadgeChip(b.label)
                                        .contextMenu {
                                            Button(role: .destructive) { removeBadge(at: idx) } label: {
                                                Label("Remove", systemImage: "trash")
                                            }
                                        }
                                }
                            }
                        } else {
                            Text("No badges yet.").font(.caption).foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding(16)
        }
        .onAppear(perform: ensureProfileExists)
        .sheet(isPresented: $showEdit) {
            if let p = profile {
                EditProfileSheet(profile: p, onSave: { save() }, onCancel: {})
            }
        }
        .alert("Add Badge", isPresented: $showAddBadge, actions: {
            TextField("Badge name", text: $newBadgeLabel)
            Button("Add") { addBadge(named: newBadgeLabel); newBadgeLabel = "" }
            Button("Cancel", role: .cancel) { newBadgeLabel = "" }
        }, message: { Text("Enter a short label, e.g., “Regionals 2026”.") })
    }

    // Helpers

    private var headerSubtitle: String {
        guard let p = profile else { return "FBLA Member" }
        return "FBLA Member • \(p.chapter.isEmpty ? "Chapter" : p.chapter), \(p.location.isEmpty ? "Location" : p.location)"
    }

    private func membershipText(_ date: Date) -> String {
        let f = DateFormatter(); f.dateStyle = .medium
        return "Active • Expires \(f.string(from: date))"
    }

    private func ensureProfileExists() {
        if profiles.isEmpty {
            let p = Profile.defaultProfile()
            modelContext.insert(p)
            try? modelContext.save()
        }
    }

    private func addBadge(named label: String) {
        guard !label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, let p = profile else { return }
        p.badges.append(Badge(label: label))
        save()
    }

    private func removeBadge(at index: Int) {
        guard let p = profile, p.badges.indices.contains(index) else { return }
        p.badges.remove(at: index)
        save()
    }

    private func save() {
        do { try modelContext.save() } catch {
            #if DEBUG
            print("Failed to save profile: \(error)")
            #endif
        }
    }
}

// MARK: Small Components

/// A compact stat tile.
private struct StatTile: View {
    let title: String
    let value: String
    let icon: String
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon).foregroundColor(.accentColor)
            VStack(alignment: .leading, spacing: 2) {
                Text(value).font(.subheadline).fontWeight(.semibold)
                Text(title).font(.caption).foregroundColor(.secondary)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// A settings row with a trailing `Toggle`.
private struct ToggleRow: View {
    let title: String
    let subtitle: String
    let systemImage: String
    @Binding var isOn: Bool
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8).fill(Color.accentColor.opacity(0.12))
                Image(systemName: systemImage).foregroundColor(.accentColor)
            }
            .frame(width: 36, height: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline).fontWeight(.semibold)
                Text(subtitle).font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            Toggle("", isOn: $isOn).labelsHidden()
        }
    }
}

/// A settings row with an inline editable text field.
private struct EditableRow: View {
    let title: String
    @State var value: String
    let systemImage: String
    var onCommit: (String) -> Void

    init(title: String, value: String, systemImage: String, onCommit: @escaping (String) -> Void) {
        self.title = title
        self._value = State(initialValue: value)
        self.systemImage = systemImage
        self.onCommit = onCommit
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8).fill(Color.accentColor.opacity(0.12))
                Image(systemName: systemImage).foregroundColor(.accentColor)
            }
            .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline).fontWeight(.semibold)
                TextField("Enter \(title.lowercased())", text: $value)
                    .font(.caption).foregroundColor(.secondary)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .submitLabel(.done)
                    .onSubmit { onCommit(value) }
            }
            Spacer()
        }
    }
}

/// A small rounded capsule badge label.
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

/// Lightweight single-row flow arrangement.
private struct FlowLayout<Content: View>: View {
    let spacing: CGFloat
    @ViewBuilder var content: () -> Content
    init(spacing: CGFloat = 8, @ViewBuilder content: @escaping () -> Content) {
        self.spacing = spacing; self.content = content
    }
    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            HStack(spacing: spacing) { content() }
        }
    }
}

// MARK: Edit Sheet

/// Inline edit form for basic profile fields (parent owns persistence).
private struct EditProfileSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var profile: Profile
    let onSave: () -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Identity")) {
                    TextField("Full name", text: $profile.fullName)
                    TextField("Email", text: $profile.email)
                        .keyboardType(.emailAddress).textInputAutocapitalization(.never)
                }
                Section(header: Text("Chapter")) {
                    TextField("Chapter", text: $profile.chapter)
                    TextField("Location", text: $profile.location)
                }
                Section(header: Text("Membership")) {
                    DatePicker("Expiration", selection: $profile.membershipExpiration, displayedComponents: .date)
                }
                Section(header: Text("Service")) {
                    Stepper("Hours: \(Int(profile.serviceHours))", value: $profile.serviceHours, in: 0...500, step: 1)
                }
                Section(header: Text("Notifications")) {
                    Toggle("Announcements", isOn: $profile.notifyAnnouncements)
                    Toggle("Updates", isOn: $profile.notifyUpdates)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { onCancel(); dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) { Button("Save") { onSave(); dismiss() }.fontWeight(.semibold) }
            }
        }
    }
}

