
// UI/Card.swift
import SwiftUI

// MARK: - Style (top-level to avoid generic nesting issues)

public enum CardStyle: Equatable {
    case surface   // Original: secondarySystemBackground + subtle border
    case frosted   // Premium glass: ultraThinMaterial + dynamic stroke + soft shadow
}

// MARK: - Card component

/// Shared card surface with built‑in styles and an environment-driven default.
/// Backwards compatible:
///   Card { ... }                      // .surface by default
/// New:
///   Card(style: .frosted) { ... }     // one-off frosted glass card
///   AnyView.cardStyle(.frosted)       // default for a subtree
public struct Card<Content: View>: View {

    /// Keep "Card.Style" spelling working for call sites if you used it.
    public typealias Style = CardStyle

    // Stored
    private let dense: Bool
    private let styleOverride: CardStyle?
    @ViewBuilder private var content: Content

    // Read default style from environment
    @Environment(\.cardStyle) private var defaultStyle

    // MARK: Initializers

    /// Backwards-compatible initializer (keeps original look & spacing)
    public init(dense: Bool = false, @ViewBuilder content: () -> Content) {
        self.dense = dense
        self.styleOverride = nil
        self.content = content()
    }

    /// Explicit style initializer (overrides environment/default)
    public init(style: CardStyle, dense: Bool = false, @ViewBuilder content: () -> Content) {
        self.dense = dense
        self.styleOverride = style
        self.content = content()
    }

    // MARK: Body

    public var body: some View {
        let style = styleOverride ?? defaultStyle
        let corner: CGFloat = (style == .frosted) ? 20 : 12
        let shape = RoundedRectangle(cornerRadius: corner, style: .continuous)

        // IMPORTANT: content drives layout first; backgrounds/borders are applied after.
        content
            .padding(dense ? 12 : 16)
            .frame(maxWidth: .infinity, alignment: .leading)

            // Background (style surface)
            .background(
                Group {
                    switch style {
                    case .surface:
                        // System secondary background so cards read on both themes
                        Color(uiColor: .secondarySystemBackground)
                            .clipShape(shape)

                    case .frosted:
                        // Glass material inside the rounded shape
                        // (Use material with shape clipping for a true blur.)
                        AnyView(EmptyView())
                            .background(.ultraThinMaterial, in: shape)
                    }
                }
            )

            // Border / edge treatment
            .overlay(
                Group {
                    switch style {
                    case .surface:
                        shape.stroke(Color.gray.opacity(0.15), lineWidth: 1)
                    case .frosted:
                        shape
                            .strokeBorder(
                                Color.white.opacity(0.28).blendMode(.overlay),
                                lineWidth: 1
                            )
                            .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
                    }
                }
            )

            // Shadows and clipping
            .clipShape(shape)
            .shadow(color: style == .frosted ? Color.black.opacity(0.12) : .clear,
                    radius: 18, y: 10)
    }
}

// MARK: - Environment (default style for a subtree)

private struct CardStyleKey: EnvironmentKey {
    static var defaultValue: CardStyle = .surface
}

public extension EnvironmentValues {
    var cardStyle: CardStyle {
        get { self[CardStyleKey.self] }
        set { self[CardStyleKey.self] = newValue }
    }
}

public extension View {
    /// Sets a default card style for this view hierarchy (children inherit it).
    /// Example:
    ///   ScrollView { ... }
    ///     .cardStyle(.frosted)
    func cardStyle(_ style: CardStyle) -> some View {
        environment(\.cardStyle, style)
    }
}
