
// Models/Profile.swift
import Foundation
import SwiftData
import SwiftUI

public enum SchoolYear: String, CaseIterable, Codable {
    case freshman, sophomore, junior, senior, other
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

public enum AppearancePreference: String, CaseIterable, Codable {
    case system, light, dark
}

@Model
public final class Badge {
    public var label: String
    public var earnedDate: Date?

    public init(label: String, earnedDate: Date? = nil) {
        self.label = label
        self.earnedDate = earnedDate
    }
}

@Model
public final class Profile {
    // Identity
    public var id: UUID = UUID()

    // Core identity
    public var fullName: String = "FBLA Member"
    public var email: String = "member@example.com"

    // Chapter / location
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

    // Onboarding fields
    public var age: Int? = nil
    public var schoolYearRaw: String = SchoolYear.other.rawValue
    public var preferredAppearanceRaw: String = AppearancePreference.system.rawValue
    public var a11yLargeText: Bool = false
    public var a11yHighContrast: Bool = false
    public var a11yReduceMotion: Bool = false

    // Notifications
    public var pushPermissionGranted: Bool = false
    public var apnsDeviceToken: String? = nil

    // Onboarding completion
    public var didCompleteSetup: Bool = false

    // Related badges
    public var badges: [Badge] = []

    // Computed
    public var schoolYear: SchoolYear {
        get { SchoolYear(rawValue: schoolYearRaw) ?? .other }
        set { schoolYearRaw = newValue.rawValue }
    }
    public var preferredAppearance: AppearancePreference {
        get { AppearancePreference(rawValue: preferredAppearanceRaw) ?? .system }
        set { preferredAppearanceRaw = newValue.rawValue }
    }
    public var preferredColorScheme: ColorScheme? {
        switch preferredAppearance {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }

    public init() {}

    public static func defaultProfile() -> Profile {
        let p = Profile()
        p.badges = [Badge(label: "Regionals"), Badge(label: "Volunteer 10h")]
        return p
    }
}

