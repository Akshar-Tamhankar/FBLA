
// Models/Event.swift
import SwiftUI

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

public struct ClubEvent: Identifiable, Codable, Hashable {
    public let id: UUID
    public var title: String
    public var date: Date
    public var category: EventCategory
    public var iconName: String
    public var accent: EventAccent
    public var isCompleted: Bool

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
        self.category = category
        self.iconName = iconName
        self.accent = accent
        self.isCompleted = isCompleted
    }

    public var accentColor: Color { accent.color }
}

