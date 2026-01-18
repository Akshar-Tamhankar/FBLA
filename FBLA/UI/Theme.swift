
// UI/Theme.swift
import SwiftUI
import UIKit

public enum Theme {
    public static let navy = Color(.sRGB, red: 11/255, green: 45/255, blue: 107/255, opacity: 1)   // #0B2D6B
    public static let red  = Color(.sRGB, red: 227/255, green: 28/255, blue: 61/255,  opacity: 1) // #E31C3D
    public static let surface = Color(uiColor: .secondarySystemBackground)
    public static let border  = Color.gray.opacity(0.15)

    public static func display(_ size: CGFloat) -> Font {
        if UIFont(name: "Poppins-SemiBold", size: size) != nil { return .custom("Poppins-SemiBold", size: size) }
        return .system(size: size, weight: .semibold, design: .rounded)
    }

    public static func text(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let name = (weight == .semibold) ? "Inter-Medium" : "Inter-Regular"
        if UIFont(name: name, size: size) != nil { return .custom(name, size: size) }
        return .system(size: size, weight: weight)
    }
}
