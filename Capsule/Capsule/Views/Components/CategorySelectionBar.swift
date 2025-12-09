//
//  CategorySelectionBar.swift
//  Capsule
//
//  The row of category buttons for starting a new recording.
//  This matches the widget design - tap a category to start recording.
//

import SwiftUI

struct CategorySelectionBar: View {
    /// Callback when a category is selected
    let onCategorySelected: (CaptureCategory) -> Void

    /// Currently hovered/pressed category for visual feedback
    @State private var pressedCategory: CaptureCategory?

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            // Category buttons in a row
            HStack(spacing: DesignSystem.Spacing.xs) {
                ForEach(CaptureCategory.allCases) { category in
                    CategoryButton(
                        category: category,
                        isPressed: pressedCategory == category,
                        onTap: { onCategorySelected(category) },
                        onPress: { pressedCategory = category },
                        onRelease: { pressedCategory = nil }
                    )
                }
            }

            // "RECORD" label below (like the widget design)
            Text("RECORD")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.mutedText)
                .tracking(4)
        }
        .padding(DesignSystem.Spacing.md)
        .cardStyle()
    }
}

// MARK: - Category Button

/// Individual category button with icon and label
struct CategoryButton: View {
    let category: CaptureCategory
    let isPressed: Bool
    let onTap: () -> Void
    let onPress: () -> Void
    let onRelease: () -> Void

    /// Haptic feedback generator
    private let haptics = UIImpactFeedbackGenerator(style: .light)

    var body: some View {
        Button(action: {
            haptics.impactOccurred()
            onTap()
        }) {
            VStack(spacing: DesignSystem.Spacing.xs) {
                // Icon
                Image(systemName: category.iconName)
                    .font(.system(size: 20, weight: .light))
                    .foregroundColor(isPressed ? category.color : DesignSystem.Colors.primaryText)

                // Label
                Text(category.displayName)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(isPressed ? category.color : DesignSystem.Colors.mutedText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(isPressed ? category.color.opacity(0.1) : Color.clear)
            .cornerRadius(DesignSystem.CornerRadius.small)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                    .stroke(isPressed ? category.color.opacity(0.5) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(PressButtonStyle(onPress: onPress, onRelease: onRelease))
    }
}

// MARK: - Press Button Style

/// Custom button style that reports press/release for visual feedback
struct PressButtonStyle: ButtonStyle {
    let onPress: () -> Void
    let onRelease: () -> Void

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed {
                    onPress()
                } else {
                    onRelease()
                }
            }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        DesignSystem.Colors.background
            .ignoresSafeArea()

        CategorySelectionBar(onCategorySelected: { category in
            print("Selected: \(category.displayName)")
        })
        .padding()
    }
}
