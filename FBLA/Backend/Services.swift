
// FBLA/Backend/Services.swift
// Swift 6 • iOS 17+
//
///  Backend scaffold for future tasks (e.g., API clients, sync, analytics).
///
///  Keep this file as a placeholder to ensure the `Backend/` folder is tracked.
///  Add concrete protocol definitions and implementations as your needs grow.
///
import Foundation

/// Example of a future repository protocol for events.
protocol EventsRepository {
    /// Fetches upcoming events from a remote source.
    func fetchUpcomingEvents() async throws -> [ClubEvent]
    /// Pushes a locally created event to a remote source.
    func push(event: ClubEvent) async throws
}

/// Example of a future repository protocol for news.
protocol NewsRepository {
    /// Loads the latest chapter/news posts from a remote source.
    func fetchLatestPosts() async throws -> [String]
}
