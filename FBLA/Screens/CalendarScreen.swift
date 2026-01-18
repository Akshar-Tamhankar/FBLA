
// Screens/CalendarScreen.swift
import SwiftUI

// MARK: - ViewModel
@MainActor
final class CalendarViewModel: ObservableObject {
    @Published var monthAnchor: Date
    @Published var selectedDate: Date?                 // set when user taps day
    @Published var filter: EventCategory? = nil        // nil = All
    @Published private(set) var allEvents: [ClubEvent] = []  // persisted

    private var eventsByDay: [Date: [ClubEvent]] = [:] // startOfDay -> events
    private let calendar: Calendar
    private let storageKey = "clubEvents_v1"

    // Cached date formatters (heavy; reuse)
    static let dfMonthYear: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = .autoupdatingCurrent
        f.dateFormat = "LLLL yyyy"
        return f
    }()
    static let dfLongDay: DateFormatter = {
        let f = DateFormatter(); f.dateStyle = .full; return f
    }()
    static let dfTime: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "h:mm a"; return f
    }()
    static let dfShort: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "EEE • MMM d • h:mm a"; return f
    }()

    init(calendar: Calendar = Calendar(identifier: .gregorian)) {
        var cal = calendar; cal.firstWeekday = 1 // Sunday
        self.calendar = cal

        let now = Date()
        let comps = cal.dateComponents([.year, .month], from: now)
        self.monthAnchor = cal.date(from: comps) ?? now

        loadEvents()
        if allEvents.isEmpty {
            seedSampleEvents()
            saveEvents()
        }
        rebuildIndex()
    }

    // MARK: - Public API
    var monthLabel: String { Self.dfMonthYear.string(from: monthAnchor) }

    func goPrevMonth() { if let d = calendar.date(byAdding: .month, value: -1, to: monthAnchor) { monthAnchor = d } }
    func goNextMonth() { if let d = calendar.date(byAdding: .month, value: 1,  to: monthAnchor) { monthAnchor = d } }
    func setSelected(date: Date?) { selectedDate = date }
    func setFilter(_ newFilter: EventCategory?) { filter = newFilter }

    /// Create a new event on a specific day (merge base day Y/M/D with time H/M)
    func addEvent(title: String, baseDay: Date, time: Date, category: EventCategory, accent: EventAccent, iconName: String) {
        let dayComps = calendar.dateComponents([.year, .month, .day], from: baseDay)
        let timeComps = calendar.dateComponents([.hour, .minute], from: time)

        var merged = DateComponents()
        merged.year = dayComps.year; merged.month = dayComps.month; merged.day = dayComps.day
        merged.hour = timeComps.hour; merged.minute = timeComps.minute

        guard let finalDate = calendar.date(from: merged) else { return }
        let evt = ClubEvent(title: title, date: finalDate, category: category, iconName: iconName, accent: accent, isCompleted: false)
        allEvents.append(evt)
        indexEvent(evt)
        saveEvents()
    }

    func toggleCompleted(_ evt: ClubEvent) {
        guard let idx = allEvents.firstIndex(where: { $0.id == evt.id }) else { return }
        allEvents[idx].isCompleted.toggle()
        reindexDay(of: allEvents[idx].date)
        saveEvents()
    }

    func delete(_ evt: ClubEvent) {
        allEvents.removeAll { $0.id == evt.id }
        reindexDay(of: evt.date)
        saveEvents()
    }

    // MARK: - Derived collections (filtered)
    var monthEvents: [ClubEvent] {
        let range = monthDateRange(for: monthAnchor)
        return allEvents.lazy.filter { evt in
            (filter == nil || evt.category == filter!) &&
            (evt.date >= range.start && evt.date <= range.end)
        }
    }

    var selectedDayEvents: [ClubEvent] {
        guard let selectedDate else { return [] }
        let day = calendar.startOfDay(for: selectedDate)
        let events = eventsByDay[day] ?? []
        return events
            .filter { filter == nil || $0.category == filter! }
            .sorted { $0.date < $1.date }
    }

    var upcomingEventsInMonth: [ClubEvent] {
        monthEvents.sorted { $0.date < $1.date }
    }

    // MARK: - Grid
    struct DayCell: Identifiable, Equatable {
        // Stable ID: use ordinal index within the grid to avoid diff churn.
        let id: Int
        let date: Date?
        let dayNumber: Int?
        let isToday: Bool
        let isPast: Bool
        let hasEvents: Bool

        struct Dot: Identifiable, Equatable {
            enum Kind { case active, completed }
            let id: Int     // small stable ID (0..2)
            let color: Color
            let kind: Kind
        }
        let dots: [Dot]
    }

    var monthGrid: [[DayCell]] {
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: monthAnchor))!
        let daysCount = calendar.range(of: .day, in: .month, for: startOfMonth)!.count
        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        let leadingZeros = firstWeekday - calendar.firstWeekday

        var cells: [DayCell] = []
        let todayStart = calendar.startOfDay(for: Date())

        // Leading blanks
        for _ in 0..<max(0, leadingZeros) {
            cells.append(DayCell(id: cells.count, date: nil, dayNumber: nil, isToday: false, isPast: false, hasEvents: false, dots: []))
        }

        // Actual days
        for day in 1...daysCount {
            let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth)!
            let thisStart = calendar.startOfDay(for: date)
            let isToday = calendar.isDate(date, inSameDayAs: todayStart)
            let isPast = thisStart < todayStart

            // Build dots for events on this day (filtered)
            let eventsHere = (eventsByDay[thisStart] ?? []).filter { filter == nil || $0.category == filter! }
            let dots = eventsHere.prefix(3).enumerated().map { i, evt in
                DayCell.Dot(id: i, color: evt.accentColor, kind: evt.isCompleted ? .completed : .active)
            }

            cells.append(
                DayCell(
                    id: cells.count,
                    date: date,
                    dayNumber: day,
                    isToday: isToday,
                    isPast: isPast,
                    hasEvents: !eventsHere.isEmpty,
                    dots: Array(dots)
                )
            )
        }

        // Trailing blanks
        while cells.count % 7 != 0 {
            cells.append(DayCell(id: cells.count, date: nil, dayNumber: nil, isToday: false, isPast: false, hasEvents: false, dots: []))
        }

        // Chunk rows of 7
        var rows: [[DayCell]] = []
        for i in stride(from: 0, to: cells.count, by: 7) {
            rows.append(Array(cells[i..<min(i + 7, cells.count)]))
        }
        return rows
    }

    // MARK: - Persistence
    private func saveEvents() {
        do {
            let data = try JSONEncoder().encode(allEvents)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            #if DEBUG
            print("Failed to save events: \(error)")
            #endif
        }
    }

    private func loadEvents() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        do {
            allEvents = try JSONDecoder().decode([ClubEvent].self, from: data)
        } catch {
            #if DEBUG
            print("Failed to load events: \(error)")
            #endif
            allEvents = []
        }
    }

    // MARK: - Indexing (performance)
    private func rebuildIndex() {
        eventsByDay.removeAll(keepingCapacity: true)
        for evt in allEvents { indexEvent(evt) }
    }

    private func indexEvent(_ evt: ClubEvent) {
        let key = calendar.startOfDay(for: evt.date)
        eventsByDay[key, default: []].append(evt)
    }

    private func reindexDay(of date: Date) {
        let key = calendar.startOfDay(for: date)
        eventsByDay[key] = allEvents.filter { calendar.isDate($0.date, inSameDayAs: date) }
    }

    // MARK: - Helpers
    private func monthDateRange(for anchor: Date) -> (start: Date, end: Date) {
        let start = calendar.date(from: calendar.dateComponents([.year, .month], from: anchor))!
        let comps = DateComponents(month: 1, day: -1)
        let end = calendar.date(byAdding: comps, to: start)!
        return (start, end)
    }

    private func seedSampleEvents() {
        // January 2026 samples (matches your design accents)
        func jan(_ day: Int, _ h: Int, _ m: Int = 0) -> Date {
            let comps = DateComponents(year: 2026, month: 1, day: day, hour: h, minute: m)
            return calendar.date(from: comps)!
        }
        allEvents = [
            ClubEvent(title: "Chapter Meeting",      date: jan(13, 16, 0), category: .event,    iconName: "person.3.fill",   accent: .blue),
            ClubEvent(title: "FBLA Practice",        date: jan(15, 15, 30), category: .event,    iconName: "bolt.fill",       accent: .orange),
            ClubEvent(title: "Competition Check-in", date: jan(17, 8, 0),  category: .event,    iconName: "flag.checkered",  accent: .purple),
            ClubEvent(title: "Submit Forms",         date: jan(10, 21, 0), category: .reminder, iconName: "bell.fill",       accent: .gray)
        ]
    }

    // MARK: - Formatting helpers
    func formatLongDay(_ d: Date) -> String { Self.dfLongDay.string(from: d) }
    func formatShort(_ d: Date)   -> String { Self.dfShort.string(from: d) }
    func timeOnly(_ d: Date)      -> String { Self.dfTime.string(from: d) }
}

// MARK: - Screen
struct CalendarScreen: View {
    @StateObject private var vm = CalendarViewModel()
    private let days = ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"]
    private let cols = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                SectionTitle(title: "Calendar")

                // Header
                Card {
                    HStack {
                        Label(vm.monthLabel, systemImage: "calendar")
                            .font(.headline)
                        Spacer()
                        HStack(spacing: 12) {
                            Button { vm.goPrevMonth() } label: { Image(systemName: "chevron.left") }
                            Button { vm.goNextMonth() } label: { Image(systemName: "chevron.right") }
                        }
                        .foregroundColor(.secondary)
                    }
                }

                // Grid
                Card {
                    VStack(spacing: 8) {
                        LazyVGrid(columns: cols, spacing: 6) {
                            ForEach(days, id: \.self) { d in
                                Text(d)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                        }

                        VStack(spacing: 6) {
                            ForEach(Array(vm.monthGrid.enumerated()), id: \.offset) { _, row in
                                LazyVGrid(columns: cols, spacing: 6) {
                                    ForEach(row) { cell in
                                        DayCellView(
                                            cell: cell,
                                            isSelected: isSelected(cell.date),
                                            onTap: { vm.setSelected(date: cell.date) },
                                            onLongPressAdd: {
                                                if let d = cell.date { vm.setSelected(date: d) }
                                            }
                                        )
                                    }
                                }
                            }
                        }
                    }
                }

                // Filters
                Card {
                    HStack(spacing: 12) {
                        Label("Filters", systemImage: "line.3.horizontal.decrease.circle")
                            .font(.headline)
                        Spacer()
                        FilterCapsule(selection: vm.filter) { new in vm.setFilter(new) }
                    }
                }

                // Upcoming
                Card {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Upcoming").font(.headline)
                        if vm.upcomingEventsInMonth.isEmpty {
                            Text("No items for this month.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(vm.upcomingEventsInMonth) { evt in
                                EventRow(
                                    title: evt.title,
                                    date: vm.formatShort(evt.date),
                                    icon: evt.iconName,
                                    accent: evt.accentColor,
                                    isCompleted: evt.isCompleted,
                                    onToggleCompleted: { vm.toggleCompleted(evt) }
                                )
                            }
                        }
                    }
                }
            }
            .padding(16)
        }
        .sheet(
            isPresented: Binding<Bool>(
                get: { vm.selectedDate != nil },
                set: { if !$0 { vm.setSelected(date: nil) } }
            )
        ) {
            if let selectedDate = vm.selectedDate {
                DayEventsSheet(
                    date: selectedDate,
                    events: vm.selectedDayEvents,
                    onToggleCompleted: { vm.toggleCompleted($0) },
                    onDelete: { vm.delete($0) },
                    onAdd: { title, time, category, accent, icon in
                        vm.addEvent(title: title, baseDay: selectedDate, time: time, category: category, accent: accent, iconName: icon)
                    }
                )
            }
        }
    }

    // MARK: - Helpers
    private func isSelected(_ date: Date?) -> Bool {
        guard let selected = vm.selectedDate, let d = date else { return false }
        return Calendar.current.isDate(selected, inSameDayAs: d)
    }
}

// MARK: - Components (unchanged visuals, minor cleanups)
private struct EventRow: View, Equatable {
    let title: String
    let date: String
    let icon: String
    let accent: Color
    let isCompleted: Bool
    let onToggleCompleted: () -> Void

    static func == (l: EventRow, r: EventRow) -> Bool {
        l.title == r.title && l.date == r.date && l.icon == r.icon && l.isCompleted == r.isCompleted
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(accent.opacity(0.15))
                Image(systemName: icon).foregroundColor(accent)
            }
            .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .strikethrough(isCompleted, color: .secondary)
                    .foregroundColor(isCompleted ? .secondary : .primary)
                Text(date).font(.caption).foregroundColor(.secondary)
            }

            Spacer()
            Button(action: onToggleCompleted) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isCompleted ? .green : .secondary)
            }
            .buttonStyle(.plain)
        }
    }
}

private struct DayCellView: View {
    let cell: CalendarViewModel.DayCell
    let isSelected: Bool
    let onTap: () -> Void
    let onLongPressAdd: () -> Void

    var body: some View {
        Button(action: { if cell.date != nil { onTap() } }) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(backgroundFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(borderColor, lineWidth: cell.isToday ? 1.5 : (isSelected ? 1 : 0))
                    )

                VStack(spacing: 4) {
                    HStack {
                        if let n = cell.dayNumber {
                            Text("\(n)")
                                .font(.caption2)
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            Text("").frame(maxWidth: .infinity, alignment: .leading)
                        }

                        if cell.isToday, cell.date != nil {
                            Text("Today")
                                .font(.system(size: 8, weight: .semibold))
                                .foregroundColor(.accentColor)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule().fill(Color.accentColor.opacity(0.15))
                                )
                        }
                    }

                    // Event dots (active = filled, completed = ring)
                    HStack(spacing: 3) {
                        ForEach(cell.dots) { dot in
                            if dot.kind == .active {
                                Circle()
                                    .fill(dot.color)
                                    .frame(width: 4, height: 4)
                                    .opacity(0.9)
                            } else {
                                Circle()
                                    .stroke(dot.color, lineWidth: 1)
                                    .frame(width: 4, height: 4)
                                    .opacity(0.9)
                            }
                        }
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 6)
            }
            .frame(height: 32)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.45).onEnded { _ in
                if cell.date != nil { onLongPressAdd() }
            }
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var backgroundFill: Color {
        guard cell.date != nil else { return .clear }
        if cell.isToday { return Color.accentColor.opacity(0.18) } // standout for today
        if cell.isPast  { return Color.gray.opacity(0.18) }        // darker for past
        return Color.gray.opacity(0.08)                            // future (original light)
    }

    private var borderColor: Color {
        if cell.isToday { return Color.accentColor.opacity(0.7) }
        if isSelected   { return Color.accentColor.opacity(0.6) }
        return .clear
    }

    private var accessibilityLabel: String {
        guard let d = cell.date else { return "Empty" }
        var base = CalendarViewModel.dfLongDay.string(from: d)
        if cell.isToday { base += ", today" }
        if cell.isPast { base += ", past day" }
        let eventsText = cell.hasEvents ? "Has events" : "No events"
        return isSelected ? "\(base), selected, \(eventsText)" : "\(base), \(eventsText)"
    }
}

// Interactive filter capsule (unchanged visuals)
private struct FilterCapsule: View {
    let selection: EventCategory?
    let onChange: (EventCategory?) -> Void

    var body: some View {
        Capsule()
            .fill(Color.gray.opacity(0.12))
            .frame(height: 32)
            .overlay(
                HStack(spacing: 0) {
                    filterButton(title: "All",      isActive: selection == nil)      { onChange(nil) }
                    divider
                    filterButton(title: "Events",   isActive: selection == .event)   { onChange(.event) }
                    divider
                    filterButton(title: "Reminders",isActive: selection == .reminder){ onChange(.reminder) }
                }
                .padding(.horizontal, 8)
            )
            .foregroundColor(.secondary)
    }

    private func filterButton(title: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(isActive ? .semibold : .regular)
                .foregroundColor(isActive ? .primary : .secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(
                    Capsule().fill(isActive ? Color.gray.opacity(0.18) : Color.clear)
                )
        }
        .buttonStyle(.plain)
    }

    private var divider: some View {
        Divider().frame(height: 16).padding(.horizontal, 8)
    }
}

// Day detail sheet (minor: uses cached formatters via vm)
private struct DayEventsSheet: View {
    let date: Date
    let events: [ClubEvent]
    let onToggleCompleted: (ClubEvent) -> Void
    let onDelete: (ClubEvent) -> Void
    let onAdd: (String, Date, EventCategory, EventAccent, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var showAdd = false

    var body: some View {
        NavigationView {
            List {
                if events.isEmpty {
                    Text("No events on this day.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(events) { evt in
                        HStack(spacing: 12) {
                            ZStack {
                                Circle().fill(evt.accentColor.opacity(0.15))
                                Image(systemName: evt.iconName).foregroundColor(evt.accentColor)
                            }
                            .frame(width: 32, height: 32)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(evt.title)
                                    .font(.subheadline).fontWeight(.semibold)
                                    .strikethrough(evt.isCompleted, color: .secondary)
                                    .foregroundColor(evt.isCompleted ? .secondary : .primary)
                                Text(CalendarViewModel.dfTime.string(from: evt.date))
                                    .font(.caption).foregroundColor(.secondary)
                            }

                            Spacer()
                            Button { onToggleCompleted(evt) } label: {
                                Image(systemName: evt.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(evt.isCompleted ? .green : .secondary)
                            }
                            .buttonStyle(.plain)
                        }
                        .swipeActions {
                            Button(role: .destructive) { onDelete(evt) } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(dayTitle(date))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Close") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showAdd = true } label: { Label("Add", systemImage: "plus") }
                }
            }
            .sheet(isPresented: $showAdd) {
                AddEventSheet(baseDay: date) { title, time, category, accent, icon in
                    onAdd(title, time, category, accent, icon)
                    showAdd = false
                }
            }
        }
    }

    private func dayTitle(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "EEEE, MMM d"; return f.string(from: d)
    }
}

private struct AddEventSheet: View {
    let baseDay: Date
    let onSave: (String, Date, EventCategory, EventAccent, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title: String = ""
    @State private var time: Date = Date()
    @State private var category: EventCategory = .event
    @State private var accent: EventAccent = .blue
    @State private var iconName: String = "calendar.badge.plus"

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Details")) {
                    TextField("Title", text: $title)
                    DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute)
                }
                Section(header: Text("Type")) {
                    Picker("Category", selection: $category) {
                        Text("Events").tag(EventCategory.event)
                        Text("Reminders").tag(EventCategory.reminder)
                    }
                    Picker("Accent", selection: $accent) {
                        ForEach(EventAccent.allCases, id: \.self) { acc in
                            Text(acc.label).tag(acc)
                        }
                    }
                }
                Section(header: Text("Icon")) {
                    HStack {
                        Image(systemName: iconName)
                        TextField("SF Symbol (e.g., bolt.fill)", text: $iconName)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(["person.3.fill","bolt.fill","flag.checkered","bell.fill","calendar","checkmark.seal"], id: \.self) { sym in
                                Button { iconName = sym } label: {
                                    ZStack {
                                        Circle().fill(Color.gray.opacity(0.12))
                                        Image(systemName: sym).foregroundColor(.secondary)
                                    }
                                    .frame(width: 36, height: 36)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                Section {
                    Button {
                        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                        onSave(title, time, category, accent, iconName)
                        dismiss()
                    } label: {
                        Label("Save Event", systemImage: "checkmark")
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .navigationTitle(addTitle(baseDay))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() } } }
        }
    }

    private func addTitle(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "MMM d"
        return "Add for \(f.string(from: date))"
    }
}
