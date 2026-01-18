
// UI/PillPageIndicatorView.swift
import SwiftUI

// MARK: - Pill Indicator (minimal + efficient)
public struct PillPageIndicatorView: View, Equatable {
    public let count: Int
    @Binding public var selectedIndex: Int

    public var pillBackground: Color = .secondary.opacity(0.15)
    public var dotColor: Color = .secondary
    public var activeDotColor: Color = .accentColor
    public var dotSize: CGFloat = 8
    public var activeDotSize: CGFloat = 11
    public var pillHorizontalPadding: CGFloat = 8
    public var pillVerticalPadding: CGFloat = 4

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

    public static func == (l: PillPageIndicatorView, r: PillPageIndicatorView) -> Bool {
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
                    .frame(width: active ? activeDotSize : dotSize, height: active ? activeDotSize : dotSize)
                    .animation(.spring(response: 0.25, dampingFraction: 0.85), value: selectedIndex)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) { selectedIndex = i }
                    }
            }
        }
        .padding(.horizontal, pillHorizontalPadding)
        .padding(.vertical, pillVerticalPadding)
        .background(Capsule().fill(pillBackground))
        .padding(.horizontal, 16)
    }
}

// MARK: - Bottom Overlay Modifier (no auto-hide; safe area optional)
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
                count: count,
                selectedIndex: $selectedIndex,
                pillBackground: pillBackground,
                dotColor: dotColor,
                activeDotColor: activeDotColor,
                dotSize: dotSize,
                activeDotSize: activeDotSize,
                pillHorizontalPadding: pillHorizontalPadding,
                pillVerticalPadding: pillVerticalPadding
            )
            .padding(.bottom, bottomPadding)

            if ignoreBottomSafeArea {
                pill.ignoresSafeArea(.container, edges: .bottom)
            } else {
                pill
            }
        }
    }
}

// MARK: - Public API
public extension View {
    /// Pins a pill-style page indicator to the bottom as a non-intrusive overlay.
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
        self.modifier(
            PillPageIndicatorModifier(
                count: count,
                selectedIndex: selectedIndex,
                bottomPadding: bottomPadding,
                ignoreBottomSafeArea: ignoreBottomSafeArea,
                pillBackground: pillBackground,
                dotColor: dotColor,
                activeDotColor: activeDotColor,
                dotSize: dotSize,
                activeDotSize: activeDotSize,
                pillHorizontalPadding: pillHorizontalPadding,
                pillVerticalPadding: pillVerticalPadding
            )
        )
    }
}
