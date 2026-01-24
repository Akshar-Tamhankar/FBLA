
// FBLA/App/Notifications.swift
// Swift 6 • iOS 17+
//
///  Notification permission and registration helper.
///
///  - Centralizes prompts and APNs registration.
///  - Exposes a small `AuthorizationState`.
///  - Opens system settings on demand.
///
import SwiftUI
import UIKit
import UserNotifications

/// Manages notification permissions, APNs registration, and system settings.
@MainActor
final class Notifications: ObservableObject {

    /// Singleton instance.
    static let shared = Notifications()

    private init() {}

    /// Notification authorization states relevant to the app.
    enum AuthorizationState { case notDetermined, granted, denied }

    /// Returns the current authorization state via `UNUserNotificationCenter`.
    func currentAuthorizationState() async -> AuthorizationState {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined: return .notDetermined
        case .denied:        return .denied
        case .authorized, .provisional, .ephemeral: return .granted
        @unknown default:    return .denied
        }
    }

    /// Prompts the user for authorization and registers for APNs if granted.
    func requestAuthorizationAndRegister() async -> AuthorizationState {
        let center = UNUserNotificationCenter.current()
        let granted = try? await center.requestAuthorization(options: [.alert, .badge, .sound])
        if granted == true {
            await MainActor.run { UIApplication.shared.registerForRemoteNotifications() }
            return .granted
        } else {
            return await currentAuthorizationState()
        }
    }

    /// Opens the app’s page in the iOS Settings app.
    func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
