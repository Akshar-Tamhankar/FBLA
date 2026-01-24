
// FBLA/UI/UIComponents.swift
// Swift 6 • iOS 17+
//
///  Shared UI utilities:
///  - `Theme`: Colors + font helpers (system fallback if custom fonts absent).
///  - `CardStyle`, `Card`: Reusable card surface with frosted & surface styles.
///  - `SectionTitle`: Page-leading title used by all screens.
///  - Micro-components: `ScaledButtonStyle`, `IconBadge`, `PrimaryCapsuleButton`, `GhostCapsuleButton`.
///  - Pill indicator: `PillPageIndicatorView` + `pillPageIndicator` bottom overlay modifier.
///
import SwiftUI
import UIKit

// MARK: Section Title

/// A consistent large title used at the top of each page.
public struct SectionTitle: View {
    /// The header text.
    public let title: String
    public init(title: String) { self.title = title }
    public var body: some View {
        HStack {
            Text(title).font(.largeTitle.bold()).foregroundColor(.primary)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }
}

// MARK: Theme

/// Shared colors and typography helpers (with safe fallbacks).
public enum Theme {
    /// Primary FBLA navy (`#0B2D6B`).
    public static let navy = Color(.sRGB, red: 11/255, green: 45/255, blue: 107/255, opacity: 1)
    /// Primary FBLA red (`#E31C3D`).
    public static let red  = Color(.sRGB, red: 227/255, green: 28/255, blue: 61/255,  opacity: 1)
    /// System secondary background (for cards).
    public static let surface = Color(uiColor: .secondarySystemBackground)
    /// Subtle border color for surfaces.
    public static let border  = Color.gray.opacity(0.15)

    /// Display font preferring Poppins; otherwise rounded system font.
    public static func display(_ size: CGFloat) -> Font {
        if UIFont(name: "Poppins-SemiBold", size: size) != nil {
            return .custom("Poppins-SemiBold", size: size)
        }
        return .system(size: size, weight: .semibold, design: .rounded)
    }

    /// Text font preferring Inter; otherwise system font.
    public static func text(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let name = (weight == .semibold) ? "Inter-Medium" : "Inter-Regular"
        if UIFont(name: name, size: size) != nil {
            return .custom(name, size: size)
        }
        return .system(size: size, weight: weight)
    }
}

// MARK: Card

/// Available presentation styles for `Card`.
public enum CardStyle: Equatable { case surface, frosted }

/// A shared card surface with a style defined by environment or override.
public struct Card<Content: View>: View {
    private let dense: Bool
    private let styleOverride: CardStyle?
    @ViewBuilder private var content: Content
    @Environment(\.cardStyle) private var defaultStyle

    /// Creates a `Card` with the environment default style.
    public init(dense: Bool = false, @ViewBuilder content: () -> Content) {
        self.dense = dense; self.styleOverride = nil; self.content = content()
    }

    /// Creates a `Card` with an explicit style override.
    public init(style: CardStyle, dense: Bool = false, @ViewBuilder content: () -> Content) {
        self.dense = dense; self.styleOverride = style; self.content = content()
    }

    public var body: some View {
        let style = styleOverride ?? defaultStyle
        let corner: CGFloat = (style == .frosted) ? 20 : 12
        let shape = RoundedRectangle(cornerRadius: corner, style: .continuous)

        content
            .padding(dense ? 12 : 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                Group {
                    switch style {
                    case .surface:
                        Color(uiColor: .secondarySystemBackground).clipShape(shape)
                    case .frosted:
                        AnyView(EmptyView()).background(.ultraThinMaterial, in: shape)
                    }
                }
            )
            .overlay(
                Group {
                    switch style {
                    case .surface:
                        shape.stroke(Color.gray.opacity(0.15), lineWidth: 1)
                    case .frosted:
                        shape
                            .strokeBorder(Color.white.opacity(0.32).blendMode(.overlay), lineWidth: 1)
                            .shadow(color: .black.opacity(0.08), radius: 1, x: 0, y: 1)
                    }
                }
            )
            .clipShape(shape)
            .shadow(color: style == .frosted ? .black.opacity(0.15) : .clear, radius: 20, y: 12)
    }
}

// MARK: Card Style Environment

private struct CardStyleKey: EnvironmentKey { static var defaultValue: CardStyle = .surface }

public extension EnvironmentValues {
    /// Default `CardStyle` used by `Card`.
    var cardStyle: CardStyle {
        get { self[CardStyleKey.self] }
        set { self[CardStyleKey.self] = newValue }
    }
}

public extension View {
    /// Overrides the default `CardStyle` for this view subtree.
    func cardStyle(_ style: CardStyle) -> some View { environment(\.cardStyle, style) }
}

// MARK: Micro Components

/// A springy button style that slightly scales the content when pressed.
public struct ScaledButtonStyle: ButtonStyle {
    /// Target scale when pressed (e.g., `0.96`).
    public let scale: CGFloat
    public init(scale: CGFloat) { self.scale = scale }
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.85), value: configuration.isPressed)
    }
}

/// A circular icon badge used for small highlights (welcome, quick actions).
public struct IconBadge: View {
    /// SF Symbol name.
    public let symbol: String
    /// Foreground + halo tint.
    public let tint: Color
    public init(symbol: String, tint: Color) { self.symbol = symbol; self.tint = tint }
    public var body: some View {
        ZStack {
            Circle().fill(tint.opacity(0.15))
            Image(systemName: symbol).foregroundColor(tint).font(.system(size: 16, weight: .semibold))
        }
        .frame(width: 34, height: 34)
        .accessibilityHidden(true)
    }
}

/// Primary red capsule call-to-action button.
public struct PrimaryCapsuleButton: View {
    /// Button title.
    public let title: String
    /// SF Symbol name.
    public let symbol: String
    /// Tap handler.
    public let action: () -> Void
    public init(title: String, symbol: String, action: @escaping () -> Void) {
        self.title = title; self.symbol = symbol; self.action = action
    }
    public var body: some View {
        Button(action: action) {
            HStack(spacing: 8) { Image(systemName: symbol); Text(title).font(Theme.text(15, weight: .semibold)) }
                .foregroundColor(.white)
                .padding(.horizontal, 14).padding(.vertical, 10)
                .background(
                    Capsule().fill(
                        LinearGradient(colors: [Theme.red, Theme.red.opacity(0.9)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                )
        }
        .buttonStyle(ScaledButtonStyle(scale: 0.96))
        .accessibilityLabel(Text(title))
    }
}

/// Secondary “ghost” outline capsule button.
public struct GhostCapsuleButton: View {
    /// Button title.
    public let title: String
    /// SF Symbol name.
    public let symbol: String
    /// Tap handler.
    public let action: () -> Void
    public init(title: String, symbol: String, action: @escaping () -> Void) {
        self.title = title; self.symbol = symbol; self.action = action
    }
    public var body: some View {
        Button(action: action) {
            HStack(spacing: 8) { Image(systemName: symbol); Text(title).font(Theme.text(14, weight: .semibold)) }
                .foregroundColor(Theme.navy)
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(Capsule().stroke(Theme.navy.opacity(0.25)))
        }
        .buttonStyle(ScaledButtonStyle(scale: 0.97))
        .accessibilityLabel(Text(title))
    }
}

// MARK: Pill Page Indicator

/// A lightweight, interactive pill‑style page indicator.
public struct PillPageIndicatorView: View, Equatable {
    /// Number of pages.
    public let count: Int
    /// Binding to the selected page index.
    @Binding public var selectedIndex: Int
    /// Background/pill colors and sizing knobs.
    public var pillBackground: Color = .secondary.opacity(0.15)
    public var dotColor: Color = .secondary
    public var activeDotColor: Color = .accentColor
    public var dotSize: CGFloat = 8
    public var activeDotSize: CGFloat = 11
    public var pillHorizontalPadding: CGFloat = 8
    public var pillVerticalPadding: CGFloat = 4

    /// Creates a pill indicator.
    public init(
        count: Int,
        selectedIndex: Binding<Int>,
        pillBackground: Color = .secondary.opacity(0.15),
        dotColor: Color = .secondary,
        activeDotColor: Color = .accentColor,
        dotSize: CGFloat = 8,
        activeDotSize: CGFloat = 11,
        pillHorizontalPadding: CGFloat = 8,
        pillVerticalPadding: CGFloat = 4
    ) {
        self.count = count
        self._selectedIndex = selectedIndex
        self.pillBackground = pillBackground
        self.dotColor = dotColor
        self.activeDotColor = activeDotColor
        self.dotSize = dotSize
        self.activeDotSize = activeDotSize
        self.pillHorizontalPadding = pillHorizontalPadding
        self.pillVerticalPadding = pillVerticalPadding
    }

    public static func == (l: Self, r: Self) -> Bool {
        l.count == r.count &&
        l.selectedIndex == r.selectedIndex &&
        l.dotSize == r.dotSize &&
        l.activeDotSize == r.activeDotSize &&
        l.pillHorizontalPadding == r.pillHorizontalPadding &&
        l.pillVerticalPadding == r.pillVerticalPadding
    }

    public var body: some View {
        HStack(spacing: 10) {
            ForEach(0..<count, id: \.self) { i in
                let active = i == selectedIndex
                Circle()
                    .fill(active ? activeDotColor : dotColor)
                    .frame(width: active ? activeDotSize : dotSize,
                           height: active ? activeDotSize : dotSize)
                    .animation(.spring(response: 0.25, dampingFraction: 0.85), value: selectedIndex)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                            selectedIndex = i
                        }
                    }
            }
        }
        .padding(.horizontal, pillHorizontalPadding)
        .padding(.vertical, pillVerticalPadding)
        .background(Capsule().fill(pillBackground))
        .padding(.horizontal, 16)
    }
}

/// Pins a pill‑style page indicator to the bottom as a non‑intrusive overlay.
private struct PillPageIndicatorModifier: ViewModifier {
    let count: Int
    @Binding var selectedIndex: Int
    var bottomPadding: CGFloat
    var ignoreBottomSafeArea: Bool
    var pillBackground: Color
    var dotColor: Color
    var activeDotColor: Color
    var dotSize: CGFloat
    var activeDotSize: CGFloat
    var pillHorizontalPadding: CGFloat
    var pillVerticalPadding: CGFloat

    func body(content: Content) -> some View {
        content.overlay(alignment: .bottom) {
            let pill = PillPageIndicatorView(
                count: count, selectedIndex: $selectedIndex,
                pillBackground: pillBackground, dotColor: dotColor, activeDotColor: activeDotColor,
                dotSize: dotSize, activeDotSize: activeDotSize,
                pillHorizontalPadding: pillHorizontalPadding, pillVerticalPadding: pillVerticalPadding
            )
            .padding(.bottom, bottomPadding)
            if ignoreBottomSafeArea { pill.ignoresSafeArea(.container, edges: .bottom) } else { pill }
        }
    }
}

public extension View {
    /// Adds a bottom-aligned pill indicator for paged content.
    func pillPageIndicator(
        count: Int,
        selectedIndex: Binding<Int>,
        bottomPadding: CGFloat = 12,
        ignoreBottomSafeArea: Bool = false,
        pillBackground: Color = .secondary.opacity(0.15),
        dotColor: Color = .secondary,
        activeDotColor: Color = .accentColor,
        dotSize: CGFloat = 8,
        activeDotSize: CGFloat = 11,
        pillHorizontalPadding: CGFloat = 8,
        pillVerticalPadding: CGFloat = 4
    ) -> some View {
        modifier(PillPageIndicatorModifier(
            count: count, selectedIndex: selectedIndex, bottomPadding: bottomPadding,
            ignoreBottomSafeArea: ignoreBottomSafeArea, pillBackground: pillBackground,
            dotColor: dotColor, activeDotColor: activeDotColor, dotSize: dotSize, activeDotSize: activeDotSize,
            pillHorizontalPadding: pillHorizontalPadding, pillVerticalPadding: pillVerticalPadding
        ))
    }
}
