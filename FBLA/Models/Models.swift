
// FBLA/Models/Models.swift
// Swift 6 • iOS 17+
//
///  SwiftData models and supporting enums used across the app.
///
///  ### Design
///  - Enums persisted as raw strings to avoid schema churn.
///  - `@Model` classes use `var` properties per Swift 6 requirements.
///  - `Profile` is single-user; `RootView` ensures a default instance.
///
import SwiftUI
import SwiftData
import Foundation

/// High-level classification of a scheduled item.
public enum EventCategory: String, CaseIterable, Codable {
    /// Meetings, practices, competitions.
    case event
    /// Lightweight reminders.
    case reminder
}

/// Accent tint for an event.
public enum EventAccent: String, CaseIterable, Codable {
    case blue, orange, purple, gray

    /// Material color mapped for the case.
    public var color: Color {
        switch self {
        case .blue:   return .blue
        case .orange: return .orange
        case .purple: return .purple
        case .gray:   return .gray
        }
    }

    /// Human-readable label.
    public var label: String {
        switch self {
        case .blue:   return "Blue"
        case .orange: return "Orange"
        case .purple: return "Purple"
        case .gray:   return "Gray"
        }
    }
}

/// A single scheduled event persisted in SwiftData.
///
/// - Note: Enum properties are stored using raw strings to keep the schema stable
///   across releases even if Swift enum cases evolve.
@Model
public final class ClubEvent {
    // Identity
    public var id: UUID
    // Core
    public var title: String
    public var date: Date
    public var iconName: String
    public var isCompleted: Bool
    // Raw enum storage
    public var categoryRaw: String
    public var accentRaw: String

    /// Typed category wrapper for `categoryRaw`.
    public var category: EventCategory {
        get { EventCategory(rawValue: categoryRaw) ?? .event }
        set { categoryRaw = newValue.rawValue }
    }

    /// Typed accent wrapper for `accentRaw`.
    public var accent: EventAccent {
        get { EventAccent(rawValue: accentRaw) ?? .blue }
        set { accentRaw = newValue.rawValue }
    }

    /// Convenience accent color for the event.
    public var accentColor: Color { accent.color }

    /// Creates a new `ClubEvent`.
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

/// School year buckets for `Profile`.
public enum SchoolYear: String, CaseIterable, Codable {
    case freshman, sophomore, junior, senior, other

    /// Human-readable label for UI.
    public var label: String {
        switch self {
        case .freshman:  return "Freshman"
        case .sophomore: return "Sophomore"
        case .junior:    return "Junior"
        case .senior:    return "Senior"
        case .other:     return "Other"
        }
    }
}

/// User-chosen appearance override.
public enum AppearancePreference: String, CaseIterable, Codable {
    case system, light, dark
}

/// A small label the user can earn (e.g., "Regionals", "Volunteer 10h").
@Model
public final class Badge {
    public var label: String
    public var earnedDate: Date?

    /// Creates a new badge.
    public init(label: String, earnedDate: Date? = nil) {
        self.label = label
        self.earnedDate = earnedDate
    }
}

/// The single-user profile containing identity, preferences, and stats.
///
/// - Important: The app assumes a single active `Profile`. `RootView` seeds one if missing.
@Model
public final class Profile {
    // Identity
    public var id: UUID = UUID()
    public var fullName: String = "FBLA Member"
    public var email: String = "member@example.com"
    // Chapter
    public var chapter: String = "Your Chapter"
    public var location: String = "City, State"
    public var chapterCode: String = ""
    // Membership
    public var membershipExpiration: Date = {
        let now = Date()
        let y = Calendar.current.component(.year, from: now)
        return Calendar.current.date(from: DateComponents(year: y, month: 6, day: 30)) ?? now
    }()
    // Preferences
    public var notifyAnnouncements: Bool = true
    public var notifyUpdates: Bool = true
    // Stats
    public var serviceHours: Double = 0
    // Onboarding inputs
    public var age: Int? = nil
    public var schoolYearRaw: String = SchoolYear.other.rawValue
    public var preferredAppearanceRaw: String = AppearancePreference.system.rawValue
    public var a11yLargeText: Bool = false
    public var a11yHighContrast: Bool = false
    public var a11yReduceMotion: Bool = false
    // Notifications
    public var pushPermissionGranted: Bool = false
    public var apnsDeviceToken: String? = nil
    // Flow completion
    public var didCompleteSetup: Bool = false
    // Badges
    public var badges: [Badge] = []

    /// Typed school year wrapper.
    public var schoolYear: SchoolYear {
        get { SchoolYear(rawValue: schoolYearRaw) ?? .other }
        set { schoolYearRaw = newValue.rawValue }
    }

    /// Typed appearance wrapper.
    public var preferredAppearance: AppearancePreference {
        get { AppearancePreference(rawValue: preferredAppearanceRaw) ?? .system }
        set { preferredAppearanceRaw = newValue.rawValue }
    }

    /// Translates preference to SwiftUI `ColorScheme`.
    public var preferredColorScheme: ColorScheme? {
        switch preferredAppearance {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }

    /// Required `@Model` initializer.
    public init() {}

    /// Returns a default profile with example badges.
    public static func defaultProfile() -> Profile {
        let p = Profile()
        p.badges = [Badge(label: "Regionals"), Badge(label: "Volunteer 10h")]
        return p
    }
}
