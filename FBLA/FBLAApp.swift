
// FBLAApp.swift
import SwiftUI
import SwiftData
import UserNotifications
import UIKit

@main
struct FBLAApp: App {
    // UIKit bridge for APNs token + notification lifecycle
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            RootView() // decides between Onboarding and main app
        }
        // SwiftData container (simple, reliable)
        .modelContainer(for: [ClubEvent.self, Profile.self, Badge.self])
    }
}

// MARK: - AppDelegate (APNs token plumbing)
final class AppDelegate: NSObject, UIApplicationDelegate {
    /// RootView sets this so we can save the APNs token into SwiftData.
    static var modelContextProvider: () -> ModelContext? = { nil }

    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Convert device token to hex string
        let token = deviceToken.map { String(format: "%02x", $0) }.joined()

        guard let ctx = Self.modelContextProvider() else { return }
        let fetch = FetchDescriptor<Profile>(predicate: nil)
        if let profile = try? ctx.fetch(fetch).first {
            profile.apnsDeviceToken = token
            profile.pushPermissionGranted = true
            try? ctx.save()
        }
        #if DEBUG
        print("✅ APNs token: \(token)")
        #endif
    }

    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        #if DEBUG
        print("⚠️ APNs registration failed: \(error)")
        #endif
    }
}

// MARK: - NotificationManager (shared helper, now colocated)
@MainActor
final class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    private init() {}

    enum AuthorizationState {
        case notDetermined, granted, denied
    }

    func currentAuthorizationState() async -> AuthorizationState {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined: return .notDetermined
        case .denied:        return .denied
        case .authorized, .provisional, .ephemeral:
            return .granted
        @unknown default:    return .denied
        }
    }

    /// Ask the user for permission, and if granted, register for APNs.
    func requestAuthorizationAndRegister() async -> AuthorizationState {
        let center = UNUserNotificationCenter.current()
        let granted = try? await center.requestAuthorization(options: [.alert, .badge, .sound])
        if granted == true {
            await MainActor.run {
                UIApplication.shared.registerForRemoteNotifications()
            }
            return .granted
        } else {
            return await currentAuthorizationState()
        }
    }

    func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
