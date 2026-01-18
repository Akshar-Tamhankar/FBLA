
// UI/Card.swift
import SwiftUI

/// Shared card container used across screens.
/// Keeps a consistent surface + subtle border, supports "dense" spacing.
public struct Card<Content: View>: View {
    private let dense: Bool
    @ViewBuilder private var content: Content

    public init(dense: Bool = false, @ViewBuilder content: () -> Content) {
        self.dense = dense
        self.content = content()
    }

    public var body: some View {
        content
            .padding(dense ? 12 : 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(uiColor: .secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.15))
            )
    }
}

