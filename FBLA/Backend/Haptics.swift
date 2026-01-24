//
//  Haptics.swift
//  FBLA
//
//  Provides lightweight wrappers for impact & notification haptics.
//

import UIKit

enum Haptics {

    /// Light impact (taps, selections)
    static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    /// Medium impact (long-press actions, adding)
    static func medium() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    /// Success (saving, completing)
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    /// Warning (deletes)
    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    /// Error (form errors, invalid input)
    static func error() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
}
