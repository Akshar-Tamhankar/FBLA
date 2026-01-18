
// Models/Event.swift
import SwiftUI
import SwiftData

public enum EventCategory: String, CaseIterable, Codable {
    case event       // meetings, practices, competitions
    case reminder    // reminders
}

public enum EventAccent: String, CaseIterable, Codable {
    case blue, orange, purple, gray

    public var color: Color {
        switch self {
        case .blue:   return .blue
        case .orange: return .orange
        case .purple: return .purple
        case .gray:   return .gray
        }
    }

    public var label: String {
        switch self {
        case .blue:   return "Blue"
        case .orange: return "Orange"
        case .purple: return "Purple"
        case .gray:   return "Gray"
        }
    }
}

/// SwiftData model for events.
/// Store enums as raw strings to keep persistence stable.
@Model
public final class ClubEvent {
    // IMPORTANT: Use `var` for stored properties in @Model (Swift 6).
    public var id: UUID

    public var title: String
    public var date: Date
    public var iconName: String
    public var isCompleted: Bool

    // Raw storage for enums
    public var categoryRaw: String
    public var accentRaw: String

    // Typed API for enums
    public var category: EventCategory {
        get { EventCategory(rawValue: categoryRaw) ?? .event }
        set { categoryRaw = newValue.rawValue }
    }

    public var accent: EventAccent {
        get { EventAccent(rawValue: accentRaw) ?? .blue }
        set { accentRaw = newValue.rawValue }
    }

    public var accentColor: Color { accent.color }

    public init(
        id: UUID = UUID(),
        title: String,
        date: Date,
        category: EventCategory,
        iconName: String,
        accent: EventAccent,
        isCompleted: Bool = false
    ) {
        self.id = id
        self.title = title
        self.date = date
        self.iconName = iconName
        self.isCompleted = isCompleted
        self.categoryRaw = category.rawValue
        self.accentRaw = accent.rawValue
    }
}
