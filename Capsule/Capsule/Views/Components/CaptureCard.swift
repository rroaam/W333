//
//  CaptureCard.swift
//  Capsule
//
//  A card displaying a capture in the home feed.
//  Shows category, title, timestamp, duration, and transcript preview.
//

import SwiftUI

struct CaptureCard: View {
    let capture: Capture

    /// For subtle press animation
    @State private var isPressed = false

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            // Top row: Category badge and timestamp
            HStack {
                CategoryBadge(category: capture.category, isActive: false)

                Spacer()

                // Duration
                HStack(spacing: DesignSystem.Spacing.xxs) {
                    Image(systemName: "waveform")
                        .font(.system(size: 10))
                    Text(capture.formattedDuration)
                        .font(DesignSystem.Typography.caption)
                }
                .foregroundColor(DesignSystem.Colors.mutedText)
            }

            // Title
            Text(capture.displayTitle)
                .font(DesignSystem.Typography.headline)
                .foregroundColor(DesignSystem.Colors.primaryText)
                .lineLimit(2)

            // Transcript preview (if available)
            if let preview = capture.transcriptPreview {
                Text(preview)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.mutedText)
                    .lineLimit(2)
            }

            // Bottom row: Time ago
            Text(capture.relativeTimeString)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.mutedText.opacity(0.7))
        }
        .padding(DesignSystem.Spacing.md)
        .cardStyle()
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            isPressed = pressing
            if pressing {
                // Haptic feedback when pressing down on card
                HapticManager.shared.lightTap()
            }
        }, perform: {})
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        DesignSystem.Colors.background
            .ignoresSafeArea()

        VStack(spacing: 12) {
            ForEach(Capture.samples) { capture in
                CaptureCard(capture: capture)
            }
        }
        .padding()
    }
}
